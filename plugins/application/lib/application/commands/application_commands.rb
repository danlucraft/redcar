module Redcar
  class Application
    class QuitCommand < Command
      def execute
        Redcar.app.call_on_plugins(:quit_guard) do |guard|
          return unless guard
        end
        Project::Manager.open_projects.each {|pr| pr.close }
        Redcar.app.quit
      end
    end
    
    class ToggleToolbar < Command

      def execute
        Redcar.app.toggle_show_toolbar
        Redcar.app.refresh_toolbar!
      end
    end
  end
end