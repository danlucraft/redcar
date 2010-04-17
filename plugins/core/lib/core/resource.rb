
module Redcar
  class Resource
    attr_reader :block, :task
    
    def self.task_queue
      Redcar.app.task_queue
    end
    
    def initialize(description, &block)
      @description = description
      @block  = block
      @value  = nil
      @future = nil
      @task   = nil
    end
    
    def value
      if @value
        @value
      else
        if @future
          if @task.pending?
            @task.cancel
            @future = nil
            @task   = nil
            @value = @block.call
          else
            @future.get
          end
        else
          @value = block.call
        end
      end
    end
    
    def compute
      @task = Resource::Task.new(self)
      @task.description = @description
      @future = Resource.task_queue.submit(@task)
    end
    
    class Task < Redcar::Task
      def initialize(resource)
        @resource = resource
      end
      
      def execute
        result = @resource.block.call
        @resource.send(:set_value_from_background, result)
        result
      end
    end
    
    private
    
    def set_value_from_background(value)
      @value  = value
      @future = nil
      @task   = nil
    end
  end
end
