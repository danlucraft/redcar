
module Com::RedcarIDE
  class DebugTools < Redcar::Plugin
    class PrintCommandHistory < Redcar::Command
      menu "Debug/Print Command History"
      composite
      def execute(tab)
        puts "Command History"
        puts Redcar::CommandHistory.history.reverse[0..15].map{|com| "  " + com.class.to_s}
      end
    end
    
    class ShowSpeedbarExample < Redcar::Command
      menu "Debug/SpeedbarExample"
      
      class ExampleSpeedbar < Redcar::Speedbar
        label "Line: "
        textbox :line
        button "Go", nil, "Return" do |sp|
          puts sp.line
          sp.close
        end
      end
      
      def execute(tab)
        sp = ExampleSpeedbar.new.show(win)
      end
    end
  end
end
