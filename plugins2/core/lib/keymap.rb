
module Redcar
  class Keymap
    def self.load #:nodoc:
      @obj_keymaps = Hash.new {|obj,key| obj[key] = [] }
      Hook.register(:keystroke)
      create_logger
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
#      puts "keypress: #{gdk_eventkey}"
      if key = clean_gdk_eventkey(gdk_eventkey)
#        Hook.trigger :keystroke, key do
          @logger.debug { "[Red] received key #{key.inspect}" }
          execute_key(key)
#        end
      else
        true 
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
#       if key_name == "Return" # FIXME!
#         return false
#       end
      if coms = bus("/redcar/keymaps/#{key_name}").data
        @logger.debug "[Red] #{coms.length} candidate commands"
        coms = coms.select do |com| 
          if com.is_a? Proc 
            true
          elsif com.ancestors.include? Redcar::Command 
            if com.executable?(Redcar.tab) 
              true
            else
              @logger.debug { "[Red] command inoperative: #{com.inspect}" } 
              @logger.debug { "      operative:  #{com.operative?.inspect}" }
              @logger.debug { "      in_range:   #{com.in_range?.inspect}" }
              @logger.debug { "      active:     #{com.active?.inspect}" }
              scope = (Redcar.doc.cursor_scope rescue nil)
              @logger.debug { "      scope:      #{com.correct_scope?(scope)}" }
              @logger.debug { "      executable: #{com.executable?(Redcar.tab)}" }
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
          return
        elsif coms.length == 1
          com = coms.first
          if com.is_a? Proc
            @logger.debug { "[Red] executing arbitrary code" }
            com.call
            true
          elsif com.ancestors.include? Redcar::Command
            @logger.debug "[Red] executing #{com.inspect}"
            com.new.do
            true
          else
            false
          end
        end
      else
        @logger.debug "[Red] no candidate commands"
        false
      end
    end

    # Turns a key_path like "Global/Ctrl+G" into "Ctrl+G" for display
    # in the menus.
    def self.display_key(key_path)
      key_path.split("/").last
    end
  end
end

