
module Redcar
  class Task
    include java.util.concurrent.Callable
 
    attr_accessor :_queue, :enqueue_time, :start_time, :completed_time
    attr_reader   :error

    def pending?
      @enqueue_time and !@start_time
    end
    
    def in_process?
      @start_time and !@completed_time
    end
    
    def completed?
      @completed_time
    end

    def call
      begin
        _queue.send(:started_task, self)
        @start_time = Time.now
        result = execute
        @completed_time = Time.now
        _queue.send(:completed_task, self)
        result
      rescue Object => e
        @error = e
        @completed_time = Time.now
        _queue.send(:completed_task, self)
        nil
      end
    end
    
    def execute
      raise "implement me!"
    end
  end
end
