
module Redcar
  class Debug
    def self.menus
      Menu::Builder.build do
        sub_menu "Debug" do
          sub_menu "Profile" do
            item "Start", Debug::StartProfilingCommand
            item "Stop",  Debug::StopProfilingCommand
          end
        end
      end
    end
    
    class StartProfilingCommand < Redcar::Command
      def execute
        require 'profiler'
        Profiler__::start_profile
      end
    end

    class StopProfilingCommand < Redcar::Command
      def execute
        str = StringIO.new
        Profiler__::print_profile(str)
        new_tab = Top::NewCommand.new.run          
        str.rewind
        new_tab.document.text = str.read
        new_tab.title= "Profile #{Time.now}"
      end
    end
  end
end