
module Redcar
  class Resource
    attr_reader :block, :task
    
    class << self
      attr_accessor :compute_synchronously
    end
    
    def self.task_queue
      Redcar.app.task_queue
    end
    
    def initialize(description=nil, &block)
      @description = description
      @block  = block
      @value  = nil
      @future = nil
      @task   = nil
      @mutex  = Mutex.new
    end
    
    def value
      return @value if @value
      
      object = nil
      @mutex.synchronize do
        if @future
          if @task.pending?
            @task.cancel
            @future = nil
            @task   = nil
            object = @block
          else
            object = @future
          end
        else
          object = @block
        end
      end
      
      case object
      when Proc
        @value = object.call
      else
        @value = object.get
      end
    end
    
    def compute
      if Resource.compute_synchronously
        @value = block.call
      else
        @mutex.synchronize do
          unless @task and @task.pending?
            @task = Resource::Task.new(self)
            @task.description = @description
            @future = Resource.task_queue.submit(@task)
          end
        end
      end
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
      @mutex.synchronize do
        @value  = value
        @future = nil
        @task   = nil
      end
    end
  end
end
