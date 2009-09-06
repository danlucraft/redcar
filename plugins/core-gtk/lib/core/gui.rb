
require 'gtk2'

module Redcar
  # Redcar::Gui sets up the Gtk main thread to begin when FreeBASE 2.0 
  # has loaded all the plugins.
  module Gui
    include FreeBASE::DataBusHelper

    def self.load
      Hook.register(:redcar_start)
    end
    
    def self.start
      set_main_loop
    end
    
    def self.set_main_loop
      bus["/system/ui/messagepump"].set_proc do
        begin
          App.log.info "starting Gui.main (in thread #{Thread.current})"
          Hook.trigger(:redcar_start)
          if in_features_process?
            Redcar::Testing::InternalCucumberRunner.begin_tests
          else
            Gtk.main_with_queue(100)
            bus["/system/shutdown"].call(1)
            # exit(0)
          end
        rescue Object => e
          $stderr.puts str=<<ERR

---------------------------
Redcar has crashed.
---------------------------

Please report this error message to the Redcar mailing list, along
with the actions you were taking at the time:

Time: #{Time.now}
Message: #{e.message}
Backtrace: \n#{e.backtrace.map{|l| "    "+l}.join("\n")}
Uname -a: #{`uname -a`.chomp}
ERR
        end
      end
    end
  end
end
