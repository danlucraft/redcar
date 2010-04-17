
module Redcar
  class Task
    include java.util.concurrent.Callable
 
    attr_accessor :_queue, :enqueue_time, :start_time, :completed_time, :description
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
    
    def cancel
      @cancelled = true
      _queue.send(:completed_task, self)
    end
    
    def cancelled?
      @cancelled
    end
    
    def call
      begin
        unless cancelled?
          _queue.send(:started_task, self)
          @start_time = Time.now
          result = execute
          @completed_time = Time.now
          _queue.send(:completed_task, self)
          result
        end
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
    
    def inspect
      "<Task>"
    end
  end
end
