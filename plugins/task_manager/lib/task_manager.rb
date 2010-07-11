
require 'erb'
require 'cgi'

module Redcar
  class TaskManager
    class OpenCommand < Redcar::Command
      
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
        "Tasks"
      end
    
      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "index.html.erb")))
        rhtml.result(binding)
      end
    end
  end
end
