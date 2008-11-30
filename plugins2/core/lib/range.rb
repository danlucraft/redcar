
module Redcar
  # A module that deals with the 'range's that commands can be in.
  module Range
    mattr_accessor :active
    
    def self.activate(range)
      #      puts "activating range #{range}"
      @commands ||= { }
      if @active.include? range
        #        puts "  already active"
        true
      else
        #        puts "  not already active"
        @active << range
        activate_commands(@commands[range]||[])
      end
    end
    
    def self.deactivate(range)
      #      puts "deactivating range #{range}"
      @commands ||= { }
      if @active.include? range
        #        puts "  was active"
        @active.delete range
        deactivate_commands(@commands[range]||[])
      else
        #        puts "  was not active"
        true
      end
    end
    
    def self.activate_commands(commands)
      commands.each{ |c| c.in_range = true }
    end
    
    def self.deactivate_commands(commands)
      commands.each{ |c| c.in_range = false }
    end
    
    def self.register_command(range, command)
      #       puts "registering command range: #{command}, #{range}"
      if valid?(range)
        @commands ||= { }
        @commands[range] ||= []
        @commands[range] << command
      else
        raise "cannot register a command with an invalid "+
        "range: #{range}"
      end
    end
    
    def self.valid?(range)
      range_ancestors = range.ancestors.map(&:to_s)
      # TODO: fix this to not hardcode references to plugins
      range.is_a? Class and
      (range == Redcar::Window or
      range <= Redcar::Tab or
      range_ancestors.include? "Redcar::EditView" or
      range_ancestors.include? "Redcar::Speedbar")
    end
  end
end
