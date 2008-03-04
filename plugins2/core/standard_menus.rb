module Redcar
  module StandardMenus
    extend FreeBASE::StandardPlugin
    extend Redcar::CommandBuilder
    extend Redcar::MenuBuilder
    
    UserCommands "File" do
      key "Global/Ctrl+N"
      def new
        win.new_tab(Tab, Gtk::Button.new("foo")).focus
      end
      
      key "Global/Ctrl+W"
      def close
        if tab
          tab.close
        end
      end
      
      key "Global/Ctrl+Super+W"
      def close_all
        win.tabs.each &:close
      end
      
      key "Global/Alt+F4"
      def quit
        Redcar::App.quit
      end
    end
    
    UserCommands "Pane" do
      key "Global/Ctrl+1"
      def unify_all
        win.unify_all
      end
      
      key "Global/Ctrl+2"
      def split_horizontal
        if tab
          tab.pane.split_horizontal
        else
          win.panes.first.split_horizontal
        end
      end
      
      key "Global/Ctrl+3"
      def split_vertical
        if tab
          tab.pane.split_vertical
        else
          win.panes.first.split_vertical
        end
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
