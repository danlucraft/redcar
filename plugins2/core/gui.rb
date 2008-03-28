
require 'gtk2'

module Redcar
  # Redcar::Gui sets up the Gtk main thread to begin when FreeBASE 2.0 
  # has loaded all the plugins.
  module Gui
    extend FreeBASE::StandardPlugin

    def self.load(plugin)
      Hook.register(:redcar_start)
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.start(plugin)
      set_main_loop(plugin)
      plugin.transition(FreeBASE::RUNNING)
    end
    
    def self.set_main_loop(plugin)
      bus["/system/ui/messagepump"].set_proc do
        begin
          puts "starting Gui.main"
          Gtk.main
          Hook.trigger(:redcar_start)
        rescue Object => e
          $stderr.puts str=<<ERR

---------------------------
Redcar has crashed.
---------------------------
Check #filename for backups of your documents. Redcar will 
notice these backups and prompt for recovery if you restart.

Please report this error message to the Redcar mailing list, along
with the actions you were taking at the time:

Time: #{Time.now}
Message: #{e.message}
Backtrace: \n#{e.backtrace.map{|l| "    "+l}.join("\n")}
Uname -a: #{`uname -a`.chomp}
ERR
        ensure
          bus["/system/shutdown"].call(1)
        end
      end
    end
  end
end
