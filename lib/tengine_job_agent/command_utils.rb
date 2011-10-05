require 'tengine_job_agent'
require 'yaml'
require 'logger'

module TengineJobAgent::CommandUtils
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
    def load_config
      config_path = Dir["{./config,/etc}/tengine_job_agent.yml"].first
      YAML.load_file(config_path)
    end

    def process(*args)
      config = load_config
      logger = new_logger(config['log_dir'])
      begin
        new(logger, args, config).process
        return 0
      rescue Exception => e
        logger.error("error: [#{e.class.name}] #{e.message}\n  " << e.backtrace.join("\n"))
        return 1
      end
    end

    def new_logger(log_dir)
      prefix = self.name.split('::').last.downcase
      Logger.new(File.expand_path("#{prefix}-#{Process.pid}.log", log_dir))
    end
  end
end
