# -*- coding: utf-8 -*-
require 'spec_helper'

describe TengineJobAgent::Run do

  before do
    @log_buffer = StringIO.new
    @logger = Logger.new(@log_buffer)
  end

  subject do
    TengineJobAgent::Run.new(@logger, "scripts/echo_foo.sh",
      YAML.load_file(File.expand_path("../config/tengine_job_agent.yml")))
  end

  context "正常起動" do
    
  end

end
