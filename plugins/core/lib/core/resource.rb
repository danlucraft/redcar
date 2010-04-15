
module Redcar
  class Resource
    def initialize(&block)
      @block = block
      @value = nil
    end
    
    def future
      Redcar.app.task_queue.submit(LambdaTask.new { @value = @block.call })
    end
    
    alias :compute :future
    
    def value
      if @value
        @value
      else
        compute.get
      end
    end
  end
end

__END__

def file_list_resource
  Resource.new { Dir["**/*"] }
end

def file_list
  @file_list ||= file_list_resource.value
end

def refresh_project
  file_list_resource.compute # must not wait
end

def get_files
  file_list # must wait
end
