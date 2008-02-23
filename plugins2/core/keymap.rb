
module Redcar
  class Keymap
    extend FreeBASE::StandardPlugin

    def self.load(plugin)
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.process(gdk_eventkey)
      kv = gdk_eventkey.keyval
      ks = gdk_eventkey.state-Gdk::Window::MOD2_MASK
      puts Gtk::Accelerator.get_label(kv, ks) 
    end
  end
end
