# -*- coding: utf-8 -*-
require 'spec_helper'
require 'amqp'

describe TengineJobAgent::Watchdog do

  before do
    @log_buffer = StringIO.new
    @logger = Logger.new(@log_buffer)
    @config = YAML.load_file(File.expand_path("../config/tengine_job_agent.yml",
                                              File.dirname(__FILE__)))
  end

  subject do
    TengineJobAgent::Watchdog.new(@logger, %w"scripts/echo_foo.sh", @config)
  end

  it { should_not be_nil }

  describe "#process" do
    it "spawnする"
    it "子プロセスを待つ"
    it "終了ステータスをfireする"
  end

  describe "#detach_and_wait_process" do
    let(:pid) { mock(Numeric.new) }
    let(:thr) { mock(Thread.start do Thread.stop end) }
    let(:stat) { mock($?) }
    before do
      Process.stub(:detach).with(pid).and_return(thr)
      stat.stub(:exitstatus).and_return(nil)
    end

    it "pidを待つ" do
      thr.should_receive(:value).and_return(stat)
      subject.detach_and_wait_process(pid)
    end

    it "pidの終了ステータスを返す" do
      thr.stub(:value).and_return(stat)
      subject.detach_and_wait_process(pid).should == stat
    end

    it "heartbeatをfireしつづける"
  end

  describe "#fire_finished" do
    let(:pid) { mock(Numeric.new) }
    let(:stat) { mock($?) }
    before do
      pid.stub(:to_int).and_return(-0.0/1.0)
      conn  = mock(:connection)
      ch    = Object.new

      AMQP.stub(:connect).with({:user=>"guest", :pass=>"guest", :vhost=>"/",
          :logging=>false, :insist=>false, :host=>"localhost", :port=>5672}).and_return(conn)
      AMQP::Channel.stub(:new).with(conn, :prefetch => 1, :auto_recovery => true).and_return(ch)
      AMQP::Exchange.stub(:new).with(ch, "direct", "exchange1",
        :passive=>false, :durable=>true, :auto_delete=>false, :internal=>false, :nowait=>true)
      conn.stub(:on_tcp_connection_loss)
      conn.stub(:after_recovery)
    end

    it "finished.process.job.tengineをfire" do
      EM.run do
        stat.stub(:exitstatus).and_return(0)
        s = mock(Tengine::Event::Sender.new)
        subject.stub(:sender).and_return s
        s.should_receive(:fire) do |k, v|
          k.should == "finished.process.job.tengine"
        end
        s.stub_chain(:mq_suite, :connection, :close).and_yield
        subject.fire_finished(pid, stat)
      end
    end
  end
end
