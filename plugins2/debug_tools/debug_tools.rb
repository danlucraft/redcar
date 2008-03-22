
module Com::RedcarIDE
  class DebugTools < Redcar::Plugin
    plugin_command
    menu "Debug/Print Command History"
    norecord
    def self.print_command_history
      puts "Command History"
      puts Redcar::CommandHistory.history.reverse[0..15].map{|com| "  " + com.name}
    end
  end
end
