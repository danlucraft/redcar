
require 'erb'
require 'cgi'

module Redcar
  class TaskManager

    def self.menus
      Menu::Builder.build do
        sub_menu "Debug", :priority => 20 do
          group(:priority => 5) do
            item "Task Manager", TaskManager::OpenCommand
            separator
          end
        end
      end
    end

    class OpenCommand < Redcar::Command
      
      def execute
        controller = Controller.new
        tab = win.new_tab(ConfigTab)
        tab.html_view.controller = controller
        tab.focus
      end
    end
    
    class Controller
      include HtmlController
      
      def title
        "Tasks"
      end
    
      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "index.html.erb")))
        rhtml.result(binding)
      end
    end
  end
end
