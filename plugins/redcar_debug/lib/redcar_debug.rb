
$:.unshift("/Users/danlucraft/projects/jruby-prof/lib")
require 'jruby-prof'

module Redcar
  class Debug
    def self.menus
      Menu::Builder.build do
        sub_menu "Debug" do
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
        require 'rubygems'
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
  end
end
