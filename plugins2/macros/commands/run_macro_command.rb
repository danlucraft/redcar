
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
      macro.reverse.each(&:do)
    end
  end
end	
