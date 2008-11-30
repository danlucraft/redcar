
module Redcar
  # A module holding the Redcar command history. The maximum length
  # defaults to 500.
  module CommandHistory
    class << self
      attr_accessor :max, :recording, :history
    end
    
    self.max       = 500
    self.recording = true
    
    # Add a command to the command history if CommandHistory.recording is
    # true.
    def self.record(com)
      if recording and com.record?
        @history << com
      end
      prune
    end
    
    def self.prune #:nodoc:
      (@history.length - @max).times { @history.delete_at(0) }
    end
    
    # Clear the command history.
    def self.clear
      @history = []
    end
  end
end

