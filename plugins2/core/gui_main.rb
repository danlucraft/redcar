
require 'gtk2'

module Redcar
  module Plugins
    module GuiMain
      extend FreeBASE::StandardPlugin

      def self.start(plugin)
        set_main_loop(plugin)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def self.set_main_loop(plugin)
        plugin["/system/ui/messagepump"].set_proc do
          begin
            puts "starting Gui.main"
            Gtk.main
          rescue => e
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
            plugin["/system/shutdown"].call(1)
          end
        end
      end
    end
  end
end
