
module Redcar
  class Logger
    LEVELS = [:debug, :info, :warn, :error]
    
    def initialize(*targets)
      @targets = targets
    end
    
    def level
      @level || :info
    end
    
    def level=(val)
      @level = val ? val.to_sym : nil
    end
    
    def close
      @targets.each {|target| target.close if target.is_a?(File)}
    end
    
    def log(msg_level, msg)
      string = "#{msg_level.to_s.rjust(5, " ")} [#{Time.now.strftime("%x %X")}] #{msg}"
      @targets.each do |target|
        target.puts(string)
      end
    end
    
    def should_log?(msg_level)
      LEVELS.index(msg_level) >= LEVELS.index(level)
    end
    
    def error(msg=nil)
      return unless should_log?(:error)
      log(:error, (block_given? ? yield : msg))
    end
    
    def warn(msg=nil)
      return unless should_log?(:warn)
      log(:warn, (block_given? ? yield : msg))
    end
    
    def info(msg=nil)
      return unless should_log?(:info)
      log(:info, (block_given? ? yield : msg))
    end
    
    def debug(msg=nil)
      return unless should_log?(:debug)
      log(:debug, (block_given? ? yield : msg))
    end
    
    def benchmark(msg, msg_level=:debug)
      s = Time.now
      result = yield
      if should_log?(msg_level)
        log(msg_level, msg + " (#{Time.now - s}s)")
      end
      result
    end
  end
end


