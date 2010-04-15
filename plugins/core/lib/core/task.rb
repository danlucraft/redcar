
module Redcar
  class Task
    include java.util.concurrent.Callable

    def call
      raise "implement me!"
    end
  end
  
  class LambdaTask < Task
    def initialize(&block)
      @block = block
    end
    
    def call
      @block.call
    end
  end
end

__END__

class UpdateCtagsTask < Task
  def call
    all_files.each do |file|
      if file.changed?
        update_ctags_append
      end
    end
  end
end

def self.project_refresh
  UpdateCtagsTask.new.enqueue
end

