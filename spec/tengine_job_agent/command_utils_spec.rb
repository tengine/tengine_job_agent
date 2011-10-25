# -*- coding: utf-8 -*-
require 'spec_helper'
require 'tmpdir'
require 'tempfile'

describe TengineJobAgent::CommandUtils do
  describe ".included" do
    it "ClassMethodsを追加" do
      foo = Class.new do
        include TengineJobAgent::CommandUtils
      end
      foo.singleton_class.ancestors.should include(TengineJobAgent::CommandUtils::ClassMethods)
    end
  end

  context "::ClassMethods" do
    describe "#load_config" do
      subject { Class.new { include TengineJobAgent::CommandUtils::ClassMethods }.new }

      it "Hashをかえす" do
        Dir.chdir File.expand_path("../..", __FILE__) do
          subject.load_config.should be_kind_of(Hash)
        end
      end

      it "./tengine_job_agent.ymlを読む"
      it "./config/tengine_job_agent.ymlを読む"
      it "/etc/tengine_job_agent.ymlを読む"
    end

    describe "#new_logger" do
      subject { Class.new { include TengineJobAgent::CommandUtils::ClassMethods }.new }
      before { subject.stub(:name).and_return("foobar") }

      it "Loggerを返す" do
        Dir.mktmpdir do |nam|
          subject.new_logger(nam).should be_kind_of(Logger)
        end
      end

      it "引数はディレクトリである" do
        Tempfile.new("") do |f|
          subject.new_logger("nonexistent").should raise_exception(Errno::ENOENT)
          subject.new_logger(f.path).should raise_exception(Errno::ENOENT)
        end
      end

      it "ログファイルは引数のディレクトリの中にできる" do
        Dir.mktmpdir do |nam|
          subject.new_logger(nam)
          nam.should have_at_least(3).files
        end
      end
    end

    describe "#process" do
      subject { Class.new { include TengineJobAgent::CommandUtils } }
      let(:instance) { mock(subject.new) }
      before do
        instance
        subject.stub(:new).with(anything, anything, anything).and_return(instance)
        subject.stub(:name).and_return(File.basename(__FILE__, ".rb"))
      end

      it "インスタンスを生成してprocessを呼ぶ" do
        instance.should_receive(:process)
        Dir.chdir File.expand_path("../..", __FILE__) do
          subject.process
        end
      end

      it "失敗するとfalseを返す" do
        instance.should_receive(:process).and_raise(RuntimeError)
        Dir.chdir File.expand_path("../..", __FILE__) do
          subject.process.should == false
        end
      end
    end
  end
end
