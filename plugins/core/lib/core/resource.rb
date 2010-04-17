
#module Redcar
#  class Resource
#    attr_reader :name
#  
#    def initialize(name, &block)
#      @name  = name
#      @block = block
#      @value = nil
#    end
#    
#    class Task < LambdaTask
#    end
#    
#    def future
#      Redcar.app.task_queue.submit(Task.new(name) { @value = @block.call })
#    end
#    
#    alias :compute :future
#    
#    def value
#      if @value
#        @value
#      else
#        compute.get
#      end
#    end
#  end
#end
