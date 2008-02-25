
module Redcar
  class Keymap
    extend FreeBASE::StandardPlugin

    def self.load(plugin)
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.process(gdk_eventkey)
      kv = gdk_eventkey.keyval
      ks = gdk_eventkey.state - Gdk::Window::MOD2_MASK
      puts Gtk::Accelerator.get_label(kv, ks) 
    end
    
    def self.clear_keymaps_from_object(obj)
      (@instance_keymaps||{}).delete obj
    end
  end
end
