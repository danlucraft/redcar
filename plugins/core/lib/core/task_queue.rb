
module Redcar
  class TaskQueue
    def initialize
      @executor = java.util.concurrent.Executors.newSingleThreadExecutor
      @mutex    = Mutex.new
      @pending   = {}
      @completed = {}
    end
    
    def submit(task)
      @mutex.synchronize do
        @pending[task] = Time.now
        task._queue = self
        task._status = :pending
        @executor.submit(task)
      end
      puts self
    end
    
    def completed_task(task)
      @mutex.synchronize do
        started = @pending[task]
        @pending.delete(task)
        @completed[task] = [started, Time.now]
      end
      puts self
    end
    
    def stop
      @executor.shutdown
    end
    
    def to_s
      r = "Queue\n"
      @mutex.synchronize do
        r << "  pending:"
        @pending.each do |task, time|
          r << "    * #{task.inspect} enqueued #{Time.now - time}s ago\n"
        end
        if @pending.empty?
          r << "  (empty)\n"
        end
        r << "\n"
        r << "  completed:\n"
        @completed.each do |task, (started, ended)|
          r << "    * #{task.inspect} took: #{ended - started}\n"
        end
        r
      end
      r
    end
  end
end

