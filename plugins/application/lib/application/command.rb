module Redcar
  # A Redcar::Command encapsulates a block of code, along with metadata
  # to describe in what ways it can be called, and how Redcar will treat the
  # command instances.
  class Command
    def self.key(key)
      @key = key
    end
    
    def self.get_key
      @key
    end
    
    def self.norecord
      @record = false
    end
    
    def self.record?
      @record == nil or @record
    end
    
    def environment(env)
      @env = env
    end
    
    def run(opts = {})
      @executor = Executor.new(self, opts)
      @executor.execute
    end
    
    private
    
    def env
      @env || {}
    end
    
    def win
      env[:win]
    end
  end
end
