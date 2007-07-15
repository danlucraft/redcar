

module Redcar
  class TextTab
    keymap "ctrl-shift (", :start_recording
    keymap "ctrl-shift )", :end_recording
    keymap "ctrl-shift E", :run_macro
    
    user_commands do
      def start_recording
        Redcar.StatusBar.main = "Recording macro..."
      end
    
      def end_recording
        mc = Macros.get_macro(self)
        if mc.length == 0
          Redcar.StatusBar.main = "stopped recording (empty macro)."
        else
          Redcar.StatusBar.main = "saved macro."
        end
      end
    
      def run_macro
        Macros.run_macro(self)
      end
    end
  end
  
  module Macros
    def Macros.get_macro(tab)
      history = tab.command_history
      macro_commands = []
      started = false
      ended = false
      history.reverse.each do |com|
        if com == [:start_recording, []]
          ended = true
        end
        if started and not ended
          macro_commands << com
        end
        if com == [:end_recording, []]
          started = true
        end
      end
      @@most_recent_macro = macro_commands.reverse
    end
    
    def Macros.run_macro(tab)
      @@most_recent_macro.each do |com|
        tab.send(com[0], *com[1])
      end
    end
  end
end
