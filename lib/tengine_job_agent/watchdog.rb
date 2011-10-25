# -*- coding: utf-8 -*-
require 'tengine_job_agent'

require 'fileutils'
require 'tempfile'
require 'tengine_event'
require 'eventmachine'

class TengineJobAgent::Watchdog
  include TengineJobAgent::CommandUtils

  def initialize(logger, args, config = {})
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
      process_status = detach_and_wait_process(pid)
      fire_finished(pid, process_status)
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
    watch_thread = Process.detach(pid)
    @logger.info("waiting process finished")
# ここになにか書く。


    # TODO detachが完了した後から、定期的に running.process.job.tengine イベントを送信するようにします。
    process_status = watch_thread.value # Thread#valueは、スレッドが終了するのを待って、そのブロックが返した値を返します
    @logger.info("process finished: " << process_status.exitstatus.inspect)
    return process_status
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
    EM.run do
      EM.next_tick do
        sender.fire("finished.process.job.tengine", {
            :level_key => level_key,
            :source_name => "job:%s/%d/%s/%s" % [
              ENV['MM_SERVER_NAME'], pid,
              ENV['MM_ROOT_JOBNET_ID'],
              ENV['MM_ACTUAL_JOB_ID']
            ],
            :sender_name => "agent:%s/%d/tengine_job_agent" % [Tengine::Event.host_name, Process.pid],
            :properties => event_properties,
          })
        @logger.info("fire_finished complete")
        EM.add_timer(1) {
          sender.mq_suite.connection.close { EM.stop }
        }
      end
    end
  end

  def sender
    @sender ||= Tengine::Event::Sender.new(@config)
  end

  private
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
