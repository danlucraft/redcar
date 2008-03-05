module Redcar
  module StandardMenus
    extend FreeBASE::StandardPlugin
    
    CommandBuilder.enable(self)
    extend Redcar::MenuBuilder
    
    UserCommands "File" do
      key "Global/Ctrl+N"
      def self.new
        win.new_tab(EditTab).focus
      end
      
      key "Global/Ctrl+W"
      def self.close
        if tab
          tab.close
        end
      end
      
      key "Global/Ctrl+Super+W"
      def self.close_all
        win.tabs.each &:close
      end
      
      key "Global/Alt+F4"
      def self.quit
        Redcar::App.quit
      end
    end
    
    UserCommands "Text" do
      key    "Global/Ctrl+U"
      inputs :selection, :line
      output :replace_input
      def self.upcase(input)
        p input
        input.upcase
      end
    end
    
    UserCommands "Pane" do
      key "Global/Ctrl+1"
      def self.unify_all
        win.unify_all
      end
      
      key "Global/Ctrl+2"
      def self.split_horizontal
        if tab
          tab.pane.split_horizontal
        else
          win.panes.first.split_horizontal
        end
      end
      
      key "Global/Ctrl+3"
      def self.split_vertical
        if tab
          tab.pane.split_vertical
        else
          win.panes.first.split_vertical
        end
      end
      
      key "Global/Ctrl+Page Down"
      def self.previous_tab
        tab.pane.gtk_notebook.prev_page
      end
      
      key "Global/Ctrl+Page Up"
      def self.next_tab
        tab.pane.gtk_notebook.next_page
      end
    end
    
    ContextMenu "Pane" do
      item "Split Horizontal",  "Pane/split_horizontal"
      item "Split Vertical",    "Pane/split_vertical"
      item "Unify All",         "Pane/unify_all"
    end
    
    MainMenu "File" do
      item "New",        "File/new",       :icon => :NEW
      item "Close",      "File/close",     :icon => :CLOSE
      item "Close All",  "File/close_all", :icon => :CLOSE
      separator
      item "Quit",       "File/quit",      :icon => :QUIT
    end
    
  end
end
