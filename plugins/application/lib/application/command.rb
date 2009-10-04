module Redcar
  class Command
    
    def run(opts = {})
      @executor = Executor.new(self, opts)
      @executor.execute
    end
    
    def record?
      true
    end
  end
end
