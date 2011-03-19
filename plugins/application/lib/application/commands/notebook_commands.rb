module Redcar
  class Application
    class OpenNewNotebookCommand < Command
      
      def execute
        win.create_notebook
      end
    end
    
    class EnlargeNotebookCommand < Command
      sensitize :multiple_notebooks
      
      def execute
        if win = Redcar.app.focussed_window
          win.enlarge_notebook(0)
        end
      end
    end

    class ResetNotebookWidthsCommand < Command
      sensitize :multiple_notebooks

      def execute
        if win = Redcar.app.focussed_window
          win.reset_notebook_widths
        end
      end
    end

    class RotateNotebooksCommand < Command
      sensitize :multiple_notebooks

      def execute
        win.rotate_notebooks
      end
    end

    class CloseNotebookCommand < Command
      sensitize :multiple_notebooks

      def execute
        unless win.notebooks.length == 1
          win.close_notebook
        end
      end
    end

    class SwitchNotebookCommand < Command
      sensitize :multiple_notebooks, :other_notebook_has_tab

      def execute
        new_notebook = win.nonfocussed_notebook
        if new_notebook.focussed_tab
          new_notebook.focussed_tab.focus
        end
      end
    end

    class MoveTabToOtherNotebookCommand < Command
      sensitize :multiple_notebooks, :open_tab

      def execute
        current_notebook = tab.notebook
        i = win.notebooks.index current_notebook

        target_notebook = win.notebooks[ (i + 1) % win.notebooks.length ]
        target_notebook.grab_tab_from(current_notebook, tab)
        tab.focus
      end
    end

  end
end