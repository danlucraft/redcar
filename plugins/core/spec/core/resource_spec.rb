
require 'java'

require File.join(File.dirname(__FILE__), *%w".. spec_helper")

TaskQueue = Redcar::TaskQueue
Task      = Redcar::Task
Resource  = Redcar::Resource

describe Resource do
  before do
    $started_tasks = []
    @block_runs = 0
    @started_flag = false
    @finish_flag  = false
    $wait_task_finish = false
    @q = TaskQueue.new
    Resource.stub!(:task_queue).and_return(@q)
  end
  
  after do
    @q.stop
  end
  
  describe "synchronous get" do
    it "should let you synchronously get the value" do
      resource = Resource.new { 101 }
      resource.value.should == 101
    end
    
    it "should cache the value across multiple calls" do
      resource = Resource.new { @block_runs += 1; 101 }
      resource.value
      resource.value
      resource.value.should == 101
      @block_runs.should == 1
    end
      
    it "should wait for a background job to finish if one is already in progress" do
      resource = Resource.new do
        @block_runs += 1
        1 until @finish_flag
      end
      resource.compute
      Thread.new do
        resource.value
      end
      sleep 0.1
      @finish_flag = true
      @block_runs.should == 1
    end
    
    it "should not wait for a background job if it pending, because it may have a long wait" do
      @q.submit(BlockingTask.new)
      resource = Resource.new do
        @block_runs += 1
        911
      end
      resource.compute
      Thread.new do
        resource.value
      end
      sleep 0.1
      resource.value.should == 911
      @block_runs.should == 1
    end
    
    it "should cancel background jobs that it overtakes" do
      @q.submit(BlockingTask.new)
      resource = Resource.new do
        @block_runs += 1
        911
      end
      resource.compute
      task = resource.task
      Thread.new do
        resource.value
      end
      sleep 0.1
      task.should be_cancelled
    end
  end
  
  it "should let you compute the resource in the background" do
    resource = Resource.new do
      1 until @started_flag
      @block_runs += 1
      @finish_flag = true
    end
    resource.compute
    @block_runs.should == 0
    @started_flag = true
    1 until @finish_flag
    @block_runs.should == 1
  end
  
  it "should have the background computed value" do
    resource = Resource.new do
      @block_runs += 1
      @started_flag = true
      999
    end
    resource.compute
    1 until @started_flag
    sleep 0.1
    resource.value.should == 999
    @block_runs.should == 1
  end
  
  it "should not compute lots of times" do
    resource = Resource.new do
      @block_runs += 1
      1 until @finish_flag
      999
    end
    20.times { resource.compute }
    @finish_flag = true
    resource.value.should == 999
    @block_runs.should == 1
  end
end


