require 'spec_helper'

describe CapBlueGreenDeploy::Tasks::Cleanup do

  class TestClass
    include CapBlueGreenDeploy::Tasks::Cleanup
  end

  subject do
    TestClass.new
  end

  before do
    @config = double("config")
    allow(@config).to receive(:load) { |&arg| arg.call }
  end

  describe "#cleanup_task_run" do
    let :local_releases do
      ["1", "2", "3"]
    end

    let :logger do
      OpenStruct.new(important: nil, info: nil)
    end

    before do
      expect(subject).to receive(:filter_local_releases!)
      allow(subject).to receive(:local_releases).and_return(local_releases)
      allow(subject).to receive(:logger).and_return(logger)
    end

    context "with old releases" do
      let :keep_releases do
        2
      end

      before do
        allow(subject).to receive(:remove_dirs)
        allow(subject).to receive(:local_releases_fullpath)
        allow(logger).to receive(:info)
        allow(subject).to receive(:keep_releases).and_return(keep_releases)
      end

      it "should log if there is old releases to clean" do
        expect(logger).to receive(:info).with("keeping #{keep_releases} of #{local_releases.length} deployed releases").and_return(logger)
        expect(subject).to receive(:logger).and_return(logger)
        subject.cleanup_task_run
      end

      it "should call remove dirs if there is old releases to clean" do
        expect(subject).to receive(:local_releases_fullpath).and_return("/teste")
        expect(subject).to receive(:remove_dirs).with("/teste")
        subject.cleanup_task_run
      end
    end

    context "without old releases" do
      it "should log if there is no old releases to clean" do
        expect(subject).to receive(:keep_releases).and_return(4)
        expect(logger).to receive(:important).with("no old releases to clean up").and_return(logger)
        expect(subject).to receive(:logger).and_return(logger)
        subject.cleanup_task_run
      end
    end
  end

  describe "#local_releases_fullpath" do
    let :local_releases do
      ["1", "2", "3"]
    end

    let :releases_path do
      "teste"
    end

    before do
      allow(subject).to receive(:local_releases).and_return(local_releases)
      allow(subject).to receive(:releases_path).and_return(releases_path)
    end

    it "should return full path of local_releases filtering keep_releases" do
      allow(subject).to receive(:keep_releases).and_return(1)
      expect(subject.local_releases_fullpath).to eq("#{releases_path}/1 #{releases_path}/2")
    end

    it "should empty if keep_releases value is greater than local_releases" do
      allow(subject).to receive(:keep_releases).and_return(4)
      expect(subject.local_releases_fullpath).to eq("")
    end
  end

  describe "#filter_local_releases!" do
    let :live_path do
      "live_path"
    end

    let :previous_path do
      "previous_path"
    end

    before do
      allow(subject).to receive(:fullpath_by_symlink).and_return("")
      allow(subject).to receive(:blue_green_live_dir).and_return(live_path)
      allow(subject).to receive(:blue_green_previous_dir).and_return(previous_path)
    end

    it "should remove current_live release from local releases list" do
      expect(subject).to receive(:fullpath_by_symlink).with(live_path).and_return(live_path)
      subject.instance_variable_set(:@local_releases, [live_path, "teste"])
      expect(subject.filter_local_releases!).to eq ["teste"]
      expect(subject.instance_variable_get(:@local_releases)).to eq ["teste"]
    end

    it "should remove previous_live release from local releases list" do
      expect(subject).to receive(:fullpath_by_symlink).with(previous_path).and_return(previous_path)
      subject.instance_variable_set(:@local_releases, [previous_path, "teste"])
      expect(subject.filter_local_releases!).to eq ["teste"]
      expect(subject.instance_variable_get(:@local_releases)).to eq ["teste"]
    end
  end

  describe "#local_releases" do
    it "should return fir list inside a path" do
      path = "/path"
      dirs = ["dir1", "dir2"]
      allow(subject).to receive(:releases_path).and_return(path)
      expect(subject).to receive(:dirs_inside).with(path).and_return(dirs)
      expect(subject.local_releases).to eq dirs
    end
  end

  describe ".task_load" do
    let :subject do
      CapBlueGreenDeploy::Tasks::Cleanup
    end

    before do
      allow(subject).to receive(:namespace)
      allow(subject).to receive(:desc)
      allow(subject).to receive(:task)
      allow(subject).to receive(:after)
    end

    context "capistrano default cleanup task" do
      before do
        allow(subject).to receive(:blue_green)
        expect(subject).to receive(:namespace).with(:deploy) { |&arg| arg.call }
      end

      it "should define default cleanup task description" do
        expect(subject).to receive(:desc).with("Clean up old releases")
        subject.task_load(@config)
      end

      it "should set default cleanup task action" do
        expect(subject).to receive(:task) { |&arg| arg.call }
        expect(subject).to receive(:cleanup_task_run)
        subject.task_load(@config)
      end
    end

    context "capistrano blue green cleanup task" do
      before do
        expect(subject).to receive(:namespace).with(:deploy) { |&arg| arg.call }
        expect(subject).to receive(:namespace).with(:blue_green) { |&arg| arg.call }
      end

      it "should set live task action" do
        expect(subject).to receive(:task).with(:cleanup, :except => { :no_release => true }) { |&arg| arg.call }
        expect(subject).to receive(:cleanup_task_run)
        subject.task_load(@config)
      end
    end
  end
end
