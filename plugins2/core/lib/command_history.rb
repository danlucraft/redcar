
module Redcar
  # A module holding the Redcar command history. The maximum length
  # defaults to 500.
  module CommandHistory
    class << self
      attr_accessor :max, :recording, :history
      delegate :length, :to => :history
      delegate :[], :to => :history
      delegate :first, :to => :history
      delegate :last, :to => :history
    end
    
    self.max       = 500
    self.recording = true
    
    # Add a command to the command history if CommandHistory.recording is
    # true.
    def self.record(command)
      if recording and command.record?
        @history << command
      end
      prune
    end
    
    # Adds a command to the command history if CommandHistory.recording is
    # true. If the last command is of the same class, it is replaced.
    def self.record_and_replace(command)
      if recording and command.record?
        if last.class == command.class
          @history[-1] = command
        else
          @history << command
        end
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

