module Redcar
  module StandardMenus
    extend FreeBASE::StandardPlugin
    
    CommandBuilder.enable(self)
    extend Redcar::MenuBuilder
    
    user_commands "File" do
      key "Global/Ctrl+N"
      def self.new
        win.new_tab(EditTab).focus
      end
      
      key "Global/Ctrl+W"
      sensitive :tab
      def self.close
        tab.close
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
    
    user_commands "Text" do
      key    "Global/Ctrl+U"
      inputs :selection, :line
      output :replace_input
      def self.upcase(input)
        p input
        input.upcase
      end
    end
    
    user_commands do
      def self.speedbarex
        win.speedbar.build do
          label   "Find:"
          textbox :find_text
          label   "Match Case"
          toggle  :match_case?, "Alt+C"
          button  "Find Next", "Alt+N | Return" do |sb|
            puts "Find next"
          end
        end
      end
    end
    
    user_commands "Pane" do
      key "Global/Ctrl+1"
      sensitive :multiple_panes
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
      
      key "Global/Ctrl+Page_Down"
      sensitive :tab
      def self.previous_tab
        puts "down:#{win.focussed_tab.label.text}"
        tab.pane.gtk_notebook.prev_page
      end
      
      key "Global/Ctrl+Page_Up"
      sensitive :tab
      def self.next_tab
        puts "up:#{win.focussed_tab.label.text}"
        puts "nb:#{win.focussed_tab.pane.gtk_notebook}"
        puts "tb:#{tab.label.text}"
        tab.pane.gtk_notebook.next_page
      end
      
      key "Global/Ctrl+Shift+Page_Down"
      sensitive :tab
      def self.move_tab_down
        tab.move_down
      end
      
      key "Global/Ctrl+Shift+Page_Up"
      sensitive :tab
      def self.move_tab_up
        tab.move_up
      end
    end
    
    context_menu "Pane" do
      item "Split Horizontal",  "Pane/split_horizontal"
      item "Split Vertical",    "Pane/split_vertical"
      item "Unify All",         "Pane/unify_all"
    end
    
    main_menu "File" do
      item "New",        "File/new",       :icon => :NEW
      item "Close",      "File/close",     :icon => :CLOSE
      item "Close All",  "File/close_all", :icon => :CLOSE
      separator
      item "Quit",       "File/quit",      :icon => :QUIT
    end
    
    main_menu "Debug" do
      item "Speedbar Example",  "speedbarex",  :icon => :NEW
    end
    
  end
end
