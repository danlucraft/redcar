module Redcar
  class StandardMenus < Redcar::Plugin
    include Redcar::MenuBuilder
    
    class NewTab < Redcar::Command
      key "Global/Ctrl+N"
      icon :NEW
      def execute
        win.new_tab(EditTab).focus
      end
    end
    
    class CloseTab < Redcar::TabCommand
      key "Global/Ctrl+W"
      def execute(tab)
        tab.close if tab
      end
    end
    
    main_menu "File" do
      item "New",        NewTab
      item "Close",      CloseTab,     :icon => :CLOSE
#      item "Close All",  "close_all", :icon => :CLOSE
#      separator
#      item "Quit",       "quit",      :icon => :QUIT
    end
#     class File
#       plugin_commands do
        
#         key "Global/Ctrl+Super+W"
#         def self.close_all
#           win.tabs.each &:close
#         end
        
#         key "Global/Alt+F4"
#         def self.quit
#           Redcar::App.quit
#         end
#       end
      
#       main_menu "File" do
#         item "New",        "new",       :icon => :NEW
# #        item "Close",      "close",     :icon => :CLOSE
#         item "Close All",  "close_all", :icon => :CLOSE
#         separator
#         item "Quit",       "quit",      :icon => :QUIT
#       end
#     end
    
#     class Text
#       CommandBuilder.enable_plugin(self)
#       extend Redcar::MenuBuilder
#       plugin_commands do
#         key    "Global/Ctrl+U"
#         inputs :selection, :line
#         output :replace_input
#         def self.upcase(input)
#           p input
#           input.upcase
#         end
#       end
#     end
    
#     plugin_commands do
#       key "Global/Ctrl+X"
#       def self.speedbarex
#         win.speedbar.build do
#           label   "Find:"
#           textbox :find_text
#           toggle  :match_case?, "Match Case", "Alt+C"
#           button  "Find Next", :GO_FORWARD, "Alt+N | Return" do |sb|
#             puts "Find next"
#           end
#         end
#       end
#     end
    
#     class Pane
#       CommandBuilder.enable_plugin(self)
#       extend Redcar::MenuBuilder    
      
#       plugin_commands do
#         key "Global/Ctrl+1"
#         sensitive :multiple_panes
#         def self.unify_all
#           win.unify_all
#         end
        
#         key "Global/Ctrl+2"
#         def self.split_horizontal
#           if tab
#             tab.pane.split_horizontal
#           else
#             win.panes.first.split_horizontal
#           end
#         end
        
#         key "Global/Ctrl+3"
#         def self.split_vertical
#           if tab
#             tab.pane.split_vertical
#           else
#             win.panes.first.split_vertical
#           end
#         end
      
#         key "Global/Ctrl+Page_Down"
#         sensitive :tab
#         def self.previous_tab
#           puts "down:#{win.focussed_tab.label.text}"
#           tab.pane.gtk_notebook.prev_page
#         end
        
#         key "Global/Ctrl+Page_Up"
#         sensitive :tab
#         def self.next_tab
#           puts "up:#{win.focussed_tab.label.text}"
#           puts "nb:#{win.focussed_tab.pane.gtk_notebook}"
#           puts "tb:#{tab.label.text}"
#           tab.pane.gtk_notebook.next_page
#         end
        
#         key "Global/Ctrl+Shift+Page_Down"
#         sensitive :tab
#         def self.move_tab_down
#           tab.move_down
#         end
        
#         key "Global/Ctrl+Shift+Page_Up"
#         sensitive :tab
#         def self.move_tab_up
#           tab.move_up
#         end
#       end
      
#       context_menu "Pane" do
#         item "Split Horizontal",  "split_horizontal"
#         item "Split Vertical",    "split_vertical"
#         item "Unify All",         "unify_all"
#       end
    
#     end
    
#     main_menu "Debug" do
#       item "Speedbar Example",  "speedbarex",  :icon => :NEW
#     end
    
  end
end
