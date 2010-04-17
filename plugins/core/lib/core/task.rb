
module Redcar
  class Task
    include java.util.concurrent.Callable
 
    attr_accessor :_queue, :enqueue_time, :start_time, :completed_time
    attr_reader   :error

    def call
      begin
        _queue.send(:started_task, self)
        @start_time = Time.now
        execute
        @completed_time = Time.now
        _queue.send(:completed_task, self)
      rescue Object => e
        @error = e
        @completed_time = Time.now
        _queue.send(:completed_task, self)
      end
    end
    
    def execute
      raise "implement me!"
    end
  end
end
