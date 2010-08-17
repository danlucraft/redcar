module Redcar
  class FindInProject
    class OpenSearch < Redcar::Command
      def execute
        if Project::Manager.focussed_project
          if (tab = find_open_instance)
            tab.html_view.controller = tab.html_view.controller # refresh
          else
            tab = win.new_tab(Redcar::HtmlTab)
            tab.html_view.controller = Redcar::FindInProject::Controller.new
          end
          tab.focus
        else
          # warning
          Application::Dialog.message_box("You need an open project to be able to use Find In Project!", :type => :error)
        end
      end

      private

      def find_open_instance
        all_tabs = Redcar.app.focussed_window.notebooks.map { |nb| nb.tabs }.flatten
        all_tabs.find do |t|
          t.is_a?(Redcar::HtmlTab) && t.title == Redcar::FindInProject::Controller.new.title
        end
      end
    end

    class EditPreferences < Redcar::Command
      def execute
        Redcar.app.make_sure_at_least_one_window_open # open a new window if needed

        Redcar::FindInProject.storage # populate the file if it isn't already

        tab  = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
        mirror = Project::FileMirror.new(File.join(Redcar.user_dir, "storage", "find_in_project.yaml"))
        tab.edit_view.document.mirror = mirror
        tab.edit_view.reset_undo
        tab.focus
      end
    end
  end
end
