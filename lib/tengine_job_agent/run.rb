# -*- coding: utf-8 -*-
require 'tengine_job_agent'
require 'timeout'
class TengineJobAgent::Run
  include TengineJobAgent::CommandUtils

  def initialize(logger, args, config = {})
    @logger = logger
    @pid_output = STDOUT
    @error_output = STDERR
    @args = args
    @config = config
    @pid_path = File.expand_path("pid_for_#{Process.pid}", @config['log_dir'])
    @timeout       = (config[:timeout      ] || ENV["MM_SYSTEM_AGENT_RUN_TIMEOUT"      ] || 600).to_i # seconds
    @timeout_alert = (config[:timeout_alert] || ENV["MM_SYSTEM_AGENT_RUN_TIMEOUT_ALERT"] || 30 ).to_i # seconds
  end

  def process
    line = nil
    process_spawned = false
    begin
      timeout(@config['timeout']) do #タイムアウト(秒)
        @logger.info("watchdog process spawning for #{@args.join(' ')}")
        pid = spawn_watchdog # watchdogプロセスをspawnで起動
        @logger.info("watchdog process spawned. PID: #{pid.inspect}")
        File.open(@pid_path, "r") do |f|
          sleep(0.1) until line = f.gets
          process_spawned = true
          @logger.info("watchdog process returned first result: #{line.inspect}")
          if line =~ /\A\d+\n?\Z/ # 数字と改行のみで構成されるならそれはPIDのはず。
            @pid_output.puts(line.strip)
            @logger.info("return PID: #{pid.inspect}")
          else
            f.rewind
            msg = f.read
            @logger.error("error occurred:\n#{msg}")
            @error_output.puts(msg)
            exit!(1)
          end
        end
      end
    rescue Timeout::Error => e
      @error_output.puts("[#{e.class.name}] #{e.message}")
      raise e # raiseしたものはTengineJobAgent::Run.processでloggerに出力されるので、ここでは何もしません
    end
  end

  # IO.pipeでパイプを使って起動したプロセスに標準出力用／標準エラー出力用のIOをそれぞれ渡して、
  # 起動したプロセスのPIDとその入力用のIOをそれぞれ戻り値として返します
  def spawn_watchdog
    @logger.info("pid file creating: #{@pid_path}")
    File.open(@pid_path, "w"){ } # ファイルをクリア
    @logger.info("pid file created: #{@pid_path}")
    # http://doc.ruby-lang.org/ja/1.9.2/method/Kernel/m/spawn.html を参考にしています
    args = @args # + [{:out => stdout_w}] #, :err => stderr_w}]
    watchdog = File.expand_path("tengine_job_agent_watchdog", File.dirname($PROGRAM_NAME))
    @logger.info("spawning watchdog: #{@pid_path}")
    pid = Process.spawn(watchdog, @pid_path, *args)
    @logger.info("spawned watchdog: #{pid}")
    return pid
  end

end
