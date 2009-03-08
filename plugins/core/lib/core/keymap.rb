
module Redcar
  class Keymap
    def self.load #:nodoc:
      @obj_keymaps = Hash.new {|obj,key| obj[key] = [] }
      Hook.register(:keystroke)
    end

    # "Page Up" -> "Page_Up"
    def self.clean_letter(letter)
      if letter.include? "Tab"
        "Tab"
      else
        letter.split(" ").join("_")
      end
    end

    def self.normalize(redcar_key)
      bits = redcar_key.split("+")
      bits = bits[0..-2].sort << bits.last
      bits.join("+")
    end

    def self.clean_gdk_eventkey(gdk_eventkey)
      kv = gdk_eventkey.keyval
      ks = gdk_eventkey.state - Gdk::Window::MOD2_MASK
      ks = ks - Gdk::Window::MOD4_MASK
      key = Gtk::Accelerator.get_label(kv, ks)
      App.log.debug "[Keymap] received key: #{key.inspect}"
      unless key[-2..-1] == " L" or key[-2..-1] == " R"
        bits = key.split("+")
        ctrl = (bits.include?("Ctrl")  ? 1 : 0)
        alt  = (bits.include?("Alt")   ? 1 : 0)
        supr = (bits.include?("Super") ? 1 : 0)
        letter = clean_letter(bits.last)
        shift = (bits.include?("Shift") && (letter =~ /^[[:alpha:]]$/ or letter.length > 1)? 1 : 0)
        key = "Ctrl+"*ctrl +
          "Super+"*supr +
          "Alt+"*alt +
          "Shift+"*shift +
          letter
        App.log.debug "[Keymap] clean key: #{key.inspect}"
        normalize(key)
      end
    end

    # Process a Gdk::EventKey (which is created on a keypress)
    def self.process(gdk_eventkey) #:nodoc:
      if key = clean_gdk_eventkey(gdk_eventkey)
        execute_key(key, gdk_eventkey)
      else
        true 
      end
    end

    # Use to register a key. key_name should look like "Ctrl+G".
    # Other examples:
    #   "Ctrl+Super+R"
    #   "Ctrl+H"
    def self.register_key_command(key_name, command)
      slot = bus("/redcar/keymaps/#{normalize(key_name)}")
      slot.data ||= []
      slot.data << command
    end

    # Removes a key from a keymap. key_name should be as in
    # register_key_command.
    def self.unregister_key(key_name)
      bus("/redcar/keymaps/#{normalize(key_name)}").prune
    end

    # Use to execute a key. key_name should be a string like "Ctrl+G".
    def self.execute_key(key_name, gdk_eventkey)
#       if key_name == "Return" # FIXME!
#         return false
#       end
      if coms = bus("/redcar/keymaps/#{normalize(key_name)}").data
        App.log.debug "[Keymap] #{coms.length} candidate commands"
        coms = coms.select do |com| 
          if com.is_a? Proc 
            true
          elsif com.ancestors.include? Redcar::Command 
            if com.executable?(Redcar.tab) 
              App.log.debug { "[Keymap] command operative: #{com.inspect}" } 
              App.log.debug { "         operative:  #{com.operative?.inspect}" }
              App.log.debug { "         in_range:   #{com.in_range?.inspect}" }
              App.log.debug { "         active:     #{com.active?.inspect}" }
              scope = (Redcar.doc.cursor_scope rescue nil)
              App.log.debug { "      scope:      #{com.correct_scope?(scope)}" }
              App.log.debug { "      executable: #{com.executable?(Redcar.tab)}" }
              true
            else
              App.log.debug { "[Keymap] command inoperative: #{com.inspect}" } 
              App.log.debug { "         operative:  #{com.operative?.inspect}" }
              App.log.debug { "         in_range:   #{com.in_range?.inspect}" }
              App.log.debug { "         active:     #{com.active?.inspect}" }
              scope = (Redcar.doc.cursor_scope rescue nil)
              App.log.debug { "         scope:      #{com.correct_scope?(scope)}" }
              App.log.debug { "         executable: #{com.executable?(Redcar.tab)}" }
              false
            end
          end
        end
        if coms.length > 1
          options = coms.map do |com|
            name = (com.get(:name) || com.to_s.split("::").last)
            [com.get(:icon), name, com]
          end
          bus("/redcar/services/context_menu_options_popup/").call(options)
          return true
        elsif coms.length == 1
          com = coms.first
          if com.is_a? Proc
            App.log.debug { "[Keymap] executing arbitrary code" }
            com.call
            return true
          elsif com.ancestors.include? Redcar::Command
            if com.pass?            
              App.log.debug "[Keymap] passing on #{com.inspect}"
              command_instance = com.new
              command_instance.gdk_event_key = gdk_eventkey
              CommandHistory.record(command_instance)
              return false
            else
              App.log.debug "[Keymap] executing #{com.inspect}"
              com.new.do
              return true
            end
          else
            return false
          end
        end
      else
        App.log.debug "[Keymap] no candidate commands"
        false
      end
    end
  end
end

