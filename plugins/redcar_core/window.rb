
require 'gtk2'

module Redcar
  module Gui
    class Window
      extend FreeBASE::StandardPlugin
      
      def self.load(plugin)
        plugin.transition(FreeBASE::LOADED)
      end
      
      def self.start(plugin)
        win = RedcarWindow.new
        win.show
        win.signal_connect("destroy") do 
          Gtk.main_quit
          plugin["/system/shutdown"].call(nil)
        end
        plugin["/system/ui/messagepump"].set_proc do
          begin
            Gtk.main
          rescue
            p $!
          ensure
            plugin["/system/shutdown"].call(1)
          end
        end
        plugin.transition(FreeBASE::RUNNING)
      end
      
      class RedcarWindow < Gtk::Window
        def initialize
          super("Redcar")
        end
      end
    end
  end
end
