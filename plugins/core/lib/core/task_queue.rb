
module Redcar
  class TaskQueue
    def initialize
      @executor = java.util.concurrent.Executors.newSingleThreadExecutor
    end
    
    def submit(task)
      @executor.submit(task)
    end
  end
end