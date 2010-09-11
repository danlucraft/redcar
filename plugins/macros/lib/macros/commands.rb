
module Redcar
  module Macros
    class StartStopRecordingCommand < Redcar::DocumentCommand
      def execute
        if info = Macros.recording[edit_view]
          edit_view.history.unsubscribe(info[:subscriber])
          Macros.session_macros << Macro.new(info[:actions])
          Macros.recording[edit_view] = nil
        else
          h = edit_view.history.subscribe do |action|
            Macros.recording[edit_view][:actions] << action
          end
          Macros.recording[edit_view] = {:subscriber => h, :actions => []}
        end
      end
    end
    
    class RunLastCommand < Redcar::DocumentCommand
      def execute
        macro = Macros.session_macros.last
        macro.run_in(edit_view)
      end
    end
    
    class NameLastMacroCommand < Redcar::Command
      def execute
        result = Application::Dialog.input("Macro Name", 
          "Assign a name to the last recorded macro:", "Nameless Macro :(")
        if result[:button] == :ok
          macro = Macros.session_macros.last
          macro.name = result[:value]
          Macros.session_macros.delete(macro)
          Macros.save_macro(macro)
        end
      end
    end
    
    class ShowMacrosCommand < Redcar::Command
      def execute
        Macros.session_macros.each do |macro|
          puts "#{macro.name}: "
          macro.actions.each do |action|
            puts "  * #{action.inspect}"
          end
        end
      end
    end
  end
end