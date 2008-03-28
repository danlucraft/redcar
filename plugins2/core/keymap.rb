
module Redcar
  class Keymap
    extend FreeBASE::StandardPlugin

    def self.load(plugin) #:nodoc:
      @obj_keymaps = Hash.new {|obj,key| obj[key] = [] }
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.start(plugin) #:nodoc:
      plugin.transition(FreeBASE::RUNNING)
    end
    
    # "Page Up" -> "Page_Up"
    def self.clean_letter(letter)
      letter.split(" ").join("_")
    end
    
    # Process a Gdk::EventKey (which is created on a keypress)
    def self.process(gdk_eventkey) #:nodoc:
      kv = gdk_eventkey.keyval
      ks = gdk_eventkey.state - Gdk::Window::MOD2_MASK
      ks = ks - Gdk::Window::MOD4_MASK
      key = Gtk::Accelerator.get_label(kv, ks)
      p key
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
        execute_key(key)
      else
        true # indicates to fall through to Gtk
      end
    end
    
    # Use to register a key. key_path should look like "Global/Ctrl+G"
    # which represents adding the key Ctrl+G to the Global keymap. 
    # Other examples:
    #   "EditTab/Ctrl+Super+R"
    #   "Snippet/Ctrl+H"
    def self.register_key(key_path, command)
      bus("/redcar/keymaps/#{key_path}").data = command
    end
    
    # Removes a key from a keymap. key_path should be as in
    # register_key.
    def self.unregister_key(key_path)
      bus("/redcar/keymaps/#{key_path}").prune
    end
    
    # Pushes a keymap (with keymap_path eg "Global" or "EditView/Snippet") 
    # onto a particular object. E.g. self.push_onto(Redcar::Window, 
    # "MyKeyMap")
    def self.push_onto(obj, keymap_path)
      @obj_keymaps[obj] << keymap_path
    end
    
    # Removes a keymap from an obj eg.
    #   Keymap.remove_from(Redcar::EditView, "EditView")
    def self.remove_from(obj, keymap_path)
      @obj_keymaps[obj].delete keymap_path
    end
    
    # Removes all keymaps from an object. 
    def self.clear_keymaps_from_object(obj)
      @obj_keymaps.delete obj
    end
    
    # Use to execute a key. key_name should be a string like "Ctrl+G".
    # Execute key will scan the keymap stacks for the first instance of
    # this key then execute the appropriate command.
    # The keymap stacks are processed in this order:
    #    current gtk widget instance
    #    current gtk widget class
    #    current tab instance
    #    current tab class
    #    current window instance
    #    current window class
    def self.execute_key(key_name)
      stack_objects = [win.focussed_gtk_widget,
                       win.focussed_gtk_widget.class,
                       win.focussed_tab, 
                       win.focussed_tab.class, 
                       win,
                       win.class]
      stack_objects.each do |stack_object|
        if stack_object
          @obj_keymaps[stack_object].reverse.each do |keymap_path|
            return if execute_key_on_keymap(key_name, keymap_path)
          end
        end
      end
      false
    end
    
    # Given a key_name like "Ctrl+G" and a keymap path like "Snippet"
    # executes the command at "/redcar/keymaps/Snippet/Ctrl+G"
    def self.execute_key_on_keymap(key_name, keymap_path)
      if com = bus("/redcar/keymaps/#{keymap_path}/#{key_name}").data
        if com.is_a? Proc
          com.call
        elsif com.ancestors.include? Redcar::Command
          if com.operative?
            com.new.do
          else
            puts "command inoperative: #{com}"
          end
        end
        true
      end
    end
    
    # Turns a key_path like "Global/Ctrl+G" into "Ctrl+G" for display
    # in the menus.
    def self.display_key(key_path)
      key_path.split("/").last
    end
  end
end

