
class ProjectSearch
  class WordSearchCommand < Redcar::Command
    sensitize :open_project
    
    def find_open_instance
      all_tabs = Redcar.app.focussed_window.notebooks.map { |nb| nb.tabs }.flatten
      all_tabs.find do |t|
        t.is_a?(Redcar::HtmlTab) && t.title == ProjectSearch::WordSearchController.new.title
      end
    end
    
    def execute
      if project = Redcar::Project::Manager.focussed_project
        if (tab = find_open_instance)
          tab.html_view.controller = tab.html_view.controller # refresh
          tab.focus
        else
          index = ProjectSearch.indexes[project.path]
          if index and index.has_content?
            tab = win.new_tab(Redcar::HtmlTab)
            tab.html_view.controller = ProjectSearch::WordSearchController.new
            tab.focus
          else
            Redcar::Application::Dialog.message_box("Your project is still being indexed.", :type => :error)
          end
        end
      else
        Redcar::Application::Dialog.message_box("You need an open project to be able to use Find In Project!", :type => :error)
      end
      return
    end
  end
  
  class RegexSearchCommand < Redcar::Command
    sensitize :open_project
    
    def execute
      if Project::Manager.focussed_project
        if (tab = find_open_instance)
          tab.html_view.controller = tab.html_view.controller # refresh
        else
          tab = win.new_tab(Redcar::HtmlTab)
          tab.html_view.controller = ProjectSearch::RegexSearchController.new
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
        t.is_a?(Redcar::HtmlTab) && t.title == ProjectSearch::RegexSearchController.new.title
      end
    end
  end

  class EditPreferences < Redcar::Command
    def execute
      Redcar.app.make_sure_at_least_one_window_open # open a new window if needed

      ProjectSearch.storage # populate the file if it isn't already

      tab  = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
      mirror = Project::FileMirror.new(File.join(Redcar.user_dir, "storage", "find_in_project.yaml"))
      tab.edit_view.document.mirror = mirror
      tab.edit_view.reset_undo
      tab.focus
    end
  end
end
