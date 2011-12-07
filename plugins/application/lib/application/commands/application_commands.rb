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
    
    class ToggleCheckForUpdatesCommand < Command
      def execute
        Application::Updates.toggle_checking_for_updates
      end
    end
    
    class OpenUpdateCommand < Command
      sensitize :update_available
      
      def execute
        new_tab = Top::OpenNewEditTabCommand.new.run
        new_tab.document.text = <<-TXT
Latest version is #{Application::Updates.latest_version}, you have #{Redcar::VERSION}.

Upgrade with:

  gem install redcar
        TXT
        new_tab.edit_view.reset_undo
        new_tab.document.set_modified(false)
        new_tab.title= 'Update'
      end
    end
  end
end