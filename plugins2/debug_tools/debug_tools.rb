
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
  end
end
