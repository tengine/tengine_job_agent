# -*- coding: utf-8 -*-
require 'spec_helper'

describe TengineJobAgent::Run do

  before do
    @log_buffer = StringIO.new
    @logger = Logger.new(@log_buffer)
    @config = YAML.load_file(File.expand_path("../config/tengine_job_agent.yml",
                                              File.dirname(__FILE__)))
  end

  subject do
    TengineJobAgent::Run.new(@logger, %w"scripts/echo_foo.sh", @config)
  end

  context "正常起動" do
    it do
      Process.stub(:spawn).with(anything, anything,anything).and_return(0)
      STDOUT.stub(:puts).with(an_instance_of(String))
      f = mock(File.open("/dev/null"))
      f.stub(:gets).and_return("0\n")
      File.stub(:open).with(an_instance_of(String), "r").and_yield(f)
      File.stub(:open).with(an_instance_of(String), "w")
      should_not be_nil
      subject.process.should == true
    end
  end

end
