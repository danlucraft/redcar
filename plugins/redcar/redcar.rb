
module Redcar
  module Top
    class NewCommand < Command
      key :osx     => "Cmd+N",
          :linux   => "Ctrl+N",
          :windows => "Ctrl+N"
      
      def execute
        puts "making a new document"
        tab = win.new_tab(Redcar::EditTab)
        tab.focus
      end
    end
    
    class NewNotebookCommand < Command
      key :osx     => "Cmd+Alt+N",
          :linux   => "Ctrl+Alt+N",
          :windows => "Ctrl+Alt+N"

      def execute
        puts "making a new notebook"
        unless win.notebooks.length > 1
          win.create_notebook
        end
      end
    end
    
    class RotateNotebooksCommand < Command
          
      def execute
        puts "rotate notebooks"
        win.rotate_notebooks
      end
    end
    
    class MoveTabToOtherNotebookCommand < Command
      # TODO: sensitize to multiple notebooks and open tab
      key :osx     => "Cmd+Alt+O",  
          :linux   => "Ctrl+Alt+O",
          :windows => "Ctrl+Alt+O"

      def execute
        puts "moveing tab to other notebook"
        if tab = win.focussed_notebook.focussed_tab
          current_notebook = tab.notebook
          target_notebook = win.notebooks.detect {|nb| nb != current_notebook}
          target_notebook.grab_tab_from(current_notebook, tab)
        end
      end
    end

    class PrintContents < EditTabCommand
      key "Cmd+P"
      
      def execute
        puts "printing contents"
        tab = win.notebook.focussed_tab
        p tab.edit_view.document.to_s
      end
    end
    
    class SetContents < EditTabCommand
      
      def execute
        puts "setting contents"
        tab = win.notebook.focussed_tab
        tab.edit_view.document.text = "class Redcar\n  include JRuby\nend\n"
      end
    end
    
    class PrintHistoryCommand < Command
      def execute
        Redcar.history.each do |c|
          puts c
        end
      end
    end
    
    class PrintScopeTreeCommand < Command
      def execute
        tab = win.notebook.focussed_tab
        puts tab.edit_view.controller.mate_text.parser.root.pretty(0)
      end
    end

    class CloseTabCommand < TabCommand
      key :osx     => "Cmd+W",
          :linux   => "Ctrl+W",
          :windows => "Ctrl+W"
      
      def execute
        # TODO: should be win.focussed_notebook
        if tab = win.focussed_notebook.focussed_tab
          tab.close
        end
      end
    end
    
    class ListTabsCommand < Command
      def execute
        p win.notebook.tabs.map {|tab| tab.class}
      end
    end
    
    def self.start
      Redcar.gui = ApplicationSWT.gui
      Redcar.app.controller = ApplicationSWT.new(Redcar.app)
      builder = Menu::Builder.new do
        sub_menu "File" do
          item "New", NewCommand
          item "New Notebook", NewNotebookCommand
          item "Open", Project::FileOpenCommand
          separator
          item "Save", Project::FileSaveCommand
          item "Save As", Project::FileSaveAsCommand
          separator
          item "Close", CloseTabCommand
        end
        sub_menu "Debug" do
          item "Print Command History", PrintHistoryCommand
          item "Print Contents", PrintContents
          item "Set Contents", SetContents
          item "List Tabs", ListTabsCommand
          item "Print Scope Tree", PrintScopeTreeCommand
          sub_menu "REPL" do
            item "Open", REPL::OpenInternalREPL
            item "Execute", REPL::CommitREPL
          end
        end
        sub_menu "View" do
          item "Rotate Notebooks", RotateNotebooksCommand
          item "Move Tab To Other Notebook", MoveTabToOtherNotebookCommand
        end
        sub_menu "Help" do
          item "Website", PrintHistoryCommand
        end
      end
      
      Redcar.app.menu = builder.menu
      Redcar.app.new_window
    end
  end
end
