
require 'erb'
require 'cgi'

module Redcar
  class ViewShortcuts
    def self.menus
      Menu::Builder.build do
        sub_menu "Help" do
          item "Keyboard Shortcuts", ViewShortcuts::ViewCommand
        end
      end
    end
  
    class ViewCommand < Redcar::Command
      def execute
        controller = Controller.new
        tab = win.new_tab(HtmlTab)
        tab.html_view.controller = controller
        tab.focus
      end
    end
    
    class Controller
      include HtmlController
      
      def title
        "Shortcuts"
      end
      
      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "index.html.erb")))
        rhtml.result(binding)
      end
    end
  end
end
