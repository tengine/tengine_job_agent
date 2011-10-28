# -*- coding: utf-8 -*-
require 'tengine_job_agent'

require 'fileutils'
require 'tempfile'
require 'tengine_event'
require 'eventmachine'
require 'uuid'

class TengineJobAgent::Watchdog
  include TengineJobAgent::CommandUtils

  def initialize(logger, args, config = {})
    @uuid = UUID.new.generate
    @logger = logger
    @pid_output = config[:pid_output] || STDOUT
    @pid_path, @program, *@args = *args
    @config = config
  end

  def process
    pid, process_status = nil, nil
    with_tmp_outs do |stdout, stderr|
      pid = spawn_process
      File.open(@pid_path, "a"){|f| f.puts(pid)} # 起動したPIDを呼び出し元に返す
      detach_and_wait_process(pid)
    end
  end

  def spawn_process
    @logger.info("spawning process " << [@program, @args].flatten.join(" "))
    options = {
      :out => @stdout.path,
      :err => @stderr.path,
      :pgroup => true}
    pid = Process.spawn(@program, *(@args + [options]))
    @logger.info("spawned process PID: #{pid}")
    return pid
  end

  def detach_and_wait_process(pid)
    @logger.info("detaching process PID: #{pid}")
    int = @config["heartbeat"]["job"]["interval"]
    if int and int > 0
      EM.run do
        EM.add_periodic_timer int do
          a = Process.waitpid2 pid, Process::WNOHANG
          if a
            @logger.info("process finished: " << a[1].exitstatus.inspect)
            fire_finished(*a)
          else
            fire_heartbeat(pid)
          end
        end
      end
    else
      p, q = Process.waitpid2 pid
      @logger.info("process finished: " << q.exitstatus.inspect)
      EM.run do
        fire_heartbeat(p, q)
      end
    end
  end

  def fire_finished(pid, process_status)
    exit_status = process_status.exitstatus # killされた場合にnilの可能性がある
    level_key = exit_status == 0 ? :info : :error
    @logger.info("fire_finished starting #{pid} #{level_key}(#{exit_status})")
    event_properties = {
      "root_jobnet_id"   => ENV['MM_ROOT_JOBNET_ID'],
      "target_jobnet_id" => ENV['MM_TARGET_JOBNET_ID'],
      "target_job_id"    => ENV['MM_ACTUAL_JOB_ID'],
      "pid" => pid,
      "exit_status" => exit_status,
      "command"   => [@program, @args].flatten.join(" "),
    }
    if level_key == :error
      user_stdout_path = output_filepath("stdout", pid)
      user_stderr_path = output_filepath("stderr", pid)
      FileUtils.cp(@stdout.path, user_stdout_path)
      FileUtils.cp(@stdout.path, user_stderr_path)
      event_properties[:stdout_log] = user_stdout_path
      event_properties[:stderr_log] = user_stderr_path
      event_properties[:message] = "Job process failed. STDOUT and STDERR were redirected to files. You can see them at #{user_stdout_path} and #{user_stderr_path} on the server #{ENV['MM_SERVER_NAME']}"
    end
    sender.fire("finished.process.job.tengine", {
      :key => @uuid,
      :level_key => level_key,
      :source_name => source_name(pid),
      :sender_name => sender_name,
      :properties => event_properties,
    })
    @logger.info("fire_finished complete")
    EM.next_tick do
      sender.mq_suite.connection.close do
        EM.stop
      end
    end
  end

  def fire_heartbeat pid
    sender.fire("job.heartbeat.tengine", {
      :key => @uuid,
      :level_key => :debug,
      :sender_name => sender_name,
      :source_name => source_name(pid),
      :occurred_at => Time.now,
      :properties => {
        "root_jobnet_id"   => ENV['MM_ROOT_JOBNET_ID'],
        "target_jobnet_id" => ENV['MM_TARGET_JOBNET_ID'],
        "target_job_id"    => ENV['MM_ACTUAL_JOB_ID'],
        "pid" => pid,
        "command"   => [@program, @args].flatten.join(" "),
      },
      :keep_connection => true,
    })
  end

  def sender
    @sender ||= Tengine::Event::Sender.new(@config)
  end

  private
  def sender_name
    @sender_name ||= sprintf "agent:%s/%d/tengine_job_agent", Tengine::Event.host_name, Process.pid
  end

  def source_name pid
    sprintf "job:%s/%d/%s/%s", ENV['MM_SERVER_NAME'], pid, ENV['MM_ROOT_JOBNET_ID'], ENV['MM_ACTUAL_JOB_ID']
  end

  def output_filepath(prefix, pid)
    File.expand_path("#{prefix}-#{pid}.log", @config[:log_dir])
  end

  def with_tmp_outs
    Tempfile.open("stdout-#{Process.pid}.log") do |tmp_stdout|
      @stdout = tmp_stdout
      begin
        Tempfile.open("stderr-#{Process.pid}.log") do |tmp_stderr|
          @stderr = tmp_stderr
          begin
            yield
          ensure
            @stderr = nil
          end
        end
      ensure
        @stdout = nil
      end
    end
  end

end
