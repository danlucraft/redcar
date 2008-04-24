
module Redcar
  class Keymap
    extend FreeBASE::StandardPlugin

    def self.load(plugin) #:nodoc:
      @obj_keymaps = Hash.new {|obj,key| obj[key] = [] }
      Hook.register(:keystroke)
      plugin.transition(FreeBASE::LOADED)
    end

    def self.start(plugin) #:nodoc:
      plugin.transition(FreeBASE::RUNNING)
    end

    # "Page Up" -> "Page_Up"
    def self.clean_letter(letter)
      if letter.include? "Tab"
        "Tab"
      else
        letter.split(" ").join("_")
      end
    end

    def self.clean_gdk_eventkey(gdk_eventkey)
      kv = gdk_eventkey.keyval
      ks = gdk_eventkey.state - Gdk::Window::MOD2_MASK
      ks = ks - Gdk::Window::MOD4_MASK
      key = Gtk::Accelerator.get_label(kv, ks)
      unless key[-2..-1] == " L" or key[-2..-1] == " R"
        bits = key.split("+")
        ctrl = (bits.include?("Ctrl")  ? 1 : 0)
        alt  = (bits.include?("Alt")   ? 1 : 0)
        supr = (bits.include?("Super") ? 1 : 0)
        shift = (bits.include?("Shift") ? 1 : 0)
        letter = bits.last
        key = "Ctrl+"*ctrl +
          "Super+"*supr +
          "Alt+"*alt +
          "Shift+"*shift +
          clean_letter(bits.last)
        key
      end
    end

    # Process a Gdk::EventKey (which is created on a keypress)
    def self.process(gdk_eventkey) #:nodoc:
      if key = clean_gdk_eventkey(gdk_eventkey)
        Hook.trigger :keystroke, key do
          p key
          execute_key(key)
        end
      else
        true # indicates to fall through to Gtk
      end
    end

    # Use to register a key. key_name should look like "Ctrl+G".
    # Other examples:
    #   "Ctrl+Super+R"
    #   "Ctrl+H"
    def self.register_key_command(key_name, command)
      slot = bus("/redcar/keymaps/#{key_name}")
      slot.data ||= []
      slot.data << command
    end

    # Removes a key from a keymap. key_name should be as in
    # register_key_command.
    def self.unregister_key(key_name)
      bus("/redcar/keymaps/#{key_name}").prune
    end

    # Use to execute a key. key_name should be a string like "Ctrl+G".
    def self.execute_key(key_name)
      if coms = bus("/redcar/keymaps/#{key_name}").data
        com = coms.first
        if com.is_a? Proc
#          puts "[Red] executing arbitrary code"
          com.call
        elsif com.ancestors.include? Redcar::Command
          scope = (Redcar.doc.cursor_scope rescue nil)
          p com
          if com.executable?(scope)
            puts "[Red] executing #{com}"
            com.new.do
          else
            puts "[Red] command inoperative: #{com}"
            puts "      in_range:#{com.in_range?.inspect}"
          end
        end
        true
      end
      false
    end

    # Turns a key_path like "Global/Ctrl+G" into "Ctrl+G" for display
    # in the menus.
    def self.display_key(key_path)
      key_path.split("/").last
    end
  end
end

