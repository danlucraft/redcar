
module Redcar
  class RunMacroCommand < Redcar::EditTabCommand
    key "Super+Shift+M"
    norecord
    
    def execute
      macro = []
      begun = nil
      CommandHistory.history.reverse.each do |command_instance|
        if begun and command_instance.is_a? RecordMacroCommand
          break
        end
        if begun and command_instance.is_a? Redcar::EditTabCommand
          macro << command_instance
        end
        if not begun and command_instance.is_a? RecordMacroCommand
          begun = true
        end
      end
      puts "Running Macro:"
      macro.reverse.each_with_index do |command_instance, i|
          puts "  #{i}. #{command_instance}"
          command_instance.do
      end
      puts "  Done"
    end
  end
end	
