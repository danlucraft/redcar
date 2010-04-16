
module Redcar
  class Task
    include java.util.concurrent.Callable

    attr_accessor :_queue, :_status
    attr_reader :name

    def initialize(name)
      @name = name
      @_status = :initialized
    end

    def call
      begin
        @_status = :executing
        execute
        @_status = :completed
      rescue Object => e
        puts "Error in task: " + e.class.to_s + ": " + e.message
        @_status = :errored
      ensure
        _queue.completed_task(self)
      end
    end
    
    def execute
      raise "implement me!"
    end
    
    def inspect
      "<#{self.class.name} #{name}>"
    end
  end
  
  class LambdaTask < Task
    def initialize(name, &block)
      super(name)
      @block = block
    end
    
    def execute
      @block.call
    end
  end
end
