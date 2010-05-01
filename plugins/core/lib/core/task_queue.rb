
module Redcar
  class TaskQueue
    MAX_COMPLETED_LENGTH = 20
    
    attr_reader :in_process, :mutex
    
    def initialize
      @executor = java.util.concurrent.Executors.newSingleThreadExecutor
      @mutex    = Mutex.new
      @pending   = []
      @completed = []
      @in_process = nil
    end
    
    def submit(task)
      @mutex.synchronize do
        @pending << task
        task._queue        = self
        task.enqueue_time = Time.now
        future = @executor.submit(task)
      end
    end
    
    def pending
      @mutex.synchronize do
        @pending.dup
      end
    end
    
    def completed
      @mutex.synchronize do
        @completed.dup
      end
    end
        
    def stop
      @mutex.synchronize do
        @executor.shutdown_now
      end
    end
    
    def cancel_all
      @mutex.synchronize do
        @pending.each {|task| task.send(:_set_cancelled) }
        @completed += @pending
        @pending   = []
      end
    end

    private
    
    def started_task(task)
      @mutex.synchronize do
        @in_process = task
        @pending.delete(task)
      end
    end
    
    def completed_task(task)
      @mutex.synchronize do
        @pending.delete(task)
        @in_process = nil if @in_process == task
        @completed << task
        if @completed.length > MAX_COMPLETED_LENGTH
          @completed = @completed[(-1*MAX_COMPLETED_LENGTH)..-1]
        end
      end
    end
  end
end

