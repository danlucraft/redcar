
module Redcar
  class Debug
    def self.menus
      Menu::Builder.build do
        sub_menu "Debug" do
          item "Command History", Debug::OpenHistoryCommand
          sub_menu "Profile" do
            item "Start Profiling", Debug::StartProfilingCommand
            item "Stop Profiling", Debug::StopProfilingCommand
            separator
            item "Show Call Graph", Debug::ShowCallGraphCommand
            item "Show Call Tree",  Debug::ShowCallTreeCommand
          end
        end
      end
    end
    
    class << self
      attr_accessor :profiling_result
    end
    
    class StartProfilingCommand < Redcar::Command
      def execute
        $:.unshift(File.dirname(__FILE__) + '/../vendor/jruby-prof/lib/')
        require 'jruby-prof'
        JRubyProf.start
      end
    end

    class StopProfilingCommand < Redcar::Command
      def execute
        Debug.profiling_result = JRubyProf.stop
      end
    end
    
    class ShowCallGraphCommand < Redcar::Command  
      def execute
        path = Redcar.user_dir + "/profile_output.html"
        JRubyProf.print_graph_html(Debug.profiling_result, path)
        tab = win.new_tab(HtmlTab)
        tab.html_view.contents = File.read(path)
        tab.focus
        FileUtils.rm_f(path)
      end
    end

    class ShowCallTreeCommand < Redcar::Command  
      def execute
        path = Redcar.user_dir + "/profile_output.html"
        JRubyProf.print_tree_html(Debug.profiling_result, path)
        tab = win.new_tab(HtmlTab)
        tab.html_view.contents = File.read(path)
        tab.focus
        FileUtils.rm_f(path)
      end
    end
    
    class OpenHistoryCommand < Redcar::Command
      
      def execute
        controller = Controller.new
        tab = win.new_tab(HtmlTab)
        tab.html_view.controller = controller
        tab.focus
      end
        
      class Controller
        include Redcar::HtmlController
        
        def title
          "History"
        end
      
        def index
          rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "history.html.erb")))
          rhtml.result(binding)
        end
      end
    end
  end
end
