
module Redcar
  class TabCommand < Redcar::Command #:nodoc:
    sensitive :tab
  end
  
  class StandardMenus < Redcar::Plugin #:nodoc:all
    include Redcar::MenuBuilder
      
    class NewTab < Redcar::Command
      key "Global/Ctrl+N"
      icon :NEW
      def execute
        win.new_tab(EditTab).focus
      end
    end
    
    class OpenTab < Redcar::Command
      key "Global/Ctrl+O"
      icon :NEW
      def execute
        if filename = Redcar::Dialog.open and File.file?(filename)
          new_tab = win.new_tab(Redcar::EditTab)
          new_tab.document.text = File.read(filename)
          new_tab.label = filename.split(/\//).last
          new_tab.focus
        end
      end
    end
    
    class CloseTab < Redcar::TabCommand
      key "Global/Ctrl+W"
      icon :CLOSE
      def execute(tab)
        tab.close if tab
      end
    end
    
    class CloseAllTabs < Redcar::TabCommand
      key "Global/Ctrl+Super+W"
      icon :CLOSE
      def execute
        win.tabs.each &:close
      end
    end
    
    class Quit < Redcar::Command
      key "Global/Alt+F4"
      icon :QUIT
      def execute
        Redcar::App.quit
      end
    end
    
    main_menu "File" do
      item "New",        NewTab
      item "Open",       OpenTab
      item "Close",      CloseTab
      item "Close All",  CloseAllTabs
      separator
      item "Quit",       Quit
    end
      
    class UnifyAll < Redcar::Command
      key "Global/Ctrl+1"
#      sensitive :multiple_panes
      def execute
        win.unify_all
      end
    end
    
    class SplitHorizontal < Redcar::Command
      key "Global/Ctrl+2"
      def execute(tab)
        if tab
          tab.pane.split_horizontal
        else
          win.panes.first.split_horizontal
        end
      end
    end
    
    class SplitVertical < Redcar::Command
      key "Global/Ctrl+3"
      def execute(tab)
        if tab
          tab.pane.split_vertical
        else
          win.panes.first.split_vertical
        end
      end
    end
    
    class PreviousTab < Redcar::TabCommand
      key "Global/Ctrl+Page_Down"
      def execute(tab)
        tab.pane.gtk_notebook.prev_page
      end
    end
    
    class NextTab < Redcar::TabCommand
      key "Global/Ctrl+Page_Up"
      def execute(tab)
        tab.pane.gtk_notebook.next_page
      end
    end
    
    class MoveTabDown < Redcar::TabCommand
      key "Global/Ctrl+Shift+Page_Down"
      def execute(tab)
        tab.move_down
      end
    end
    
    class MoveTabUp < Redcar::TabCommand
      key "Global/Ctrl+Shift+Page_Up"
      def self.move_tab_up
        tab.move_up
      end
    end
    
    context_menu "Pane" do
      item "Split Horizontal",  SplitHorizontal
      item "Split Vertical",    SplitVertical
      item "Unify All",         UnifyAll
    end
  end
end
