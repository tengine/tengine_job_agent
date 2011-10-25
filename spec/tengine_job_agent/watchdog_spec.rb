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
    echo_foo = File.expand_path "../scripts/echo_foo.sh", __FILE__
    TengineJobAgent::Watchdog.new(@logger, %W"/dev/null #{echo_foo}", @config)
  end

  it { should_not be_nil }

  describe "#process" do
    let(:pid) { mock(Numeric.new) }
    let(:stat) { mock($?) }
    before do
      bigzero = (1 << 1024).coerce(0)[0]
      pid.stub(:to_int).and_return(bigzero)
      stat.stub(:exitstatus).and_return(bigzero)
    end

    it "spawnする" do
      subject.should_receive(:spawn_process).and_return(pid)
      subject.stub(:detach_and_wait_process).with(pid).and_return(stat)
      subject.stub(:fire_finished).with(pid, stat)
      subject.process
    end

    it "子プロセスを待つ" do
      subject.stub(:spawn_process).and_return(pid)
      subject.should_receive(:detach_and_wait_process).and_return(stat)
      subject.stub(:fire_finished).with(pid, stat)
      subject.process
    end

    it "終了ステータスをfireする" do
      subject.stub(:spawn_process).and_return(pid)
      subject.stub(:detach_and_wait_process).and_return(stat)
      subject.should_receive(:fire_finished).with(pid, stat)
      subject.process
    end
  end

  describe "#spawn_process" do
    let(:pid) { mock(Numeric.new) }
    let(:thr) { mock(Thread.start do Thread.stop end) }
    let(:stat) { mock($?) }
    before do
      o = mock(STDOUT)
      e = mock(STDERR)
      o.stub(:path).and_return(String.new)
      e.stub(:path).and_return(String.new)
      subject.instance_eval do
        @stdout = o
        @stderr = e
      end
    end

    it "spawnする" do
      echo_foo = File.expand_path "../scripts/echo_foo.sh", __FILE__
      Process.should_receive(:spawn).with(echo_foo, an_instance_of(Hash)).and_return(pid)
      subject.spawn_process.should == pid
    end    
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

      o = mock(STDOUT)
      e = mock(STDERR)
      o.stub(:path).and_return(String.new)
      e.stub(:path).and_return(String.new)
      subject.instance_eval do
        @stdout = o
        @stderr = e
      end
    end

    it "finished.process.job.tengineをfire" do
      EM.run do
        stat.stub(:exitstatus).and_return(0)
        s = mock(Tengine::Event::Sender.new)
        subject.stub(:sender).and_return s
        s.should_receive(:fire) do |k, v|
          k.should == "finished.process.job.tengine"
          v[:level_key].should == :info
          v[:properties]["pid"].should == pid
          v[:properties]["exit_status"].should == stat.exitstatus
        end
        s.stub_chain(:mq_suite, :connection, :close).and_yield
        subject.fire_finished(pid, stat)
      end
    end

    it "プロセスが失敗していた場合" do
      EM.run do
        FileUtils.stub(:cp).with(an_instance_of(String), an_instance_of(String))
        stat.stub(:exitstatus).and_return(256)
        s = mock(Tengine::Event::Sender.new)
        subject.stub(:sender).and_return s
        s.should_receive(:fire) do |k, v|
          k.should == "finished.process.job.tengine"
          v[:level_key].should == :error
          v[:properties][:message].should =~ /^Job process failed./
        end
        s.stub_chain(:mq_suite, :connection, :close).and_yield
        subject.fire_finished(pid, stat)
      end
    end
  end

  describe "#sender" do
    before do
      conn = mock(:connection)
      conn.stub(:on_tcp_connection_loss)
      conn.stub(:after_recovery)
      AMQP.stub(:connect).with({:user=>"guest", :pass=>"guest", :vhost=>"/",
          :logging=>false, :insist=>false, :host=>"localhost", :port=>5672}).and_return(conn)
    end
    subject { TengineJobAgent::Watchdog.new(@logger, %w"", @config).sender }
    it { should be_kind_of(Tengine::Event::Sender) }
  end
end
