module Redcar
  # The Keymap stack is as follows:
  # 1. Global
  # 2. Focussed tab class
  # 3. Focussed tab instance
  # 4. Focussed widget class
  # 5. Focussed widget instance
  # 6. (GTK widget keybindings)
  #
  # Lower numbers have higher priority. The global and 'class' keymaps
  # are usually pre-defined, and the instance keymaps are usually
  # activated programatically. E.g. the snippets keymap is activated
  # on a particular tab at runtime.
  module Keymap
    KEYMAP_SCOPES = []
    
    def self.included(klass)
      KEYMAP_SCOPES << klass.to_s
    end
    
    class Global
      include Keymap
    end
    
    def self.load_keymaps
      commands = Redcar.image.find_with_tags(:command)
      commands.each do |command|
        if command[:activated_by] == :key_combination
          self.attach_command(command)
        end
      end
    end
    
    def self.attach_command(command)
      @keymaps ||= {}
      @keymaps[command[:activated_by_value]] = command
    end
    
    def self.execute_keystroke(keystroke)
      command = @keymaps[keystroke.to_s]
      Command.execute(command)
      command
    end
  end
    
  class KeyStroke
    attr_reader :modifiers, :keyname
    def initialize(modifiers, keyname)
      @modifiers = modifiers.sort_by {|m| m.to_s }
      @keyname = keyname
    end
    
    def to_s
      if self.modifiers.length > 0
        str = self.modifiers.join('-')+" "
      else
        str = ""
      end
      str+self.keyname
    end
    
    def ==(other)
      other = KeyStroke.parse(other)
      self.keyname == other.keyname and
        self.modifiers == other.modifiers
    end
    
    def self.parse(str)
      return str if str.is_a? KeyStroke
      str = str.strip
      if str.strip.include? " "
        str_mods, str_keyname = str.strip.split(" ")
        mods = str_mods.split('-').map do |sm|
          case sm.downcase
          when "alt", "a"
            :alt
          when "control", "ctrl", "c"
            :control
          when "shift", "sh", "s"
            :shift
          when "caps", "lock", "capslock", "cl"
            :caps
          when "super", "sup", "spr", "sp"
            :super
          end
        end
        self.new(mods, str_keyname)
      else
        self.new([], str)
      end
    end
  end
  
  class KeyCatcher
    attr_reader :history_size, :history
    def initialize(options={})
      options = process_params(options,
                               { :history => 500 })
      @history_size = options[:history]
      @history = []
    end
    
    def enable(win=Redcar.current_window)
      if @keyhandler_id
        win.signal_handler_unblock(@keyhandler_id)
      else
        id = win.signal_connect('key-press-event') do |gtk_widget, gdk_eventkey|
          continue = Redcar.keycatcher.issue_from_gdk_eventkey(gdk_eventkey)
          continue
        end
        @keyhandler_id = id
      end
    end
    
    def disable(win=Redcar.current_window)
      if @keyhandler_id
        win.signal_handler_block(@keyhandler_id)
      end
    end
    
    def add_to_history(keystroke)
      keystroke = KeyStroke.parse(keystroke)
      @history << keystroke
      if @history.length == @history_size
        @history = @history[1..-1]
      end
    end

    def clear_history
      @history = []
    end
    
    def issue(kb)
      issue_from_keystroke(kb)
    end
    
    def issue_from_keystroke(keystroke)
      keystroke = KeyStroke.parse(keystroke)
      exists = Keymap.execute_keystroke(keystroke)
      if exists
        add_to_history(keystroke)
        true
      else
        false
      end
    end
    
    def gdk_eventkey_to_keystroke(gdk_eventkey)
      keyname = " "
      keyname[0] = Gdk::Keyval.to_unicode(gdk_eventkey.keyval)
      keyname = Gdk::Keyval.to_name(gdk_eventkey.keyval) if keyname=="\000"
      gdk_modifier_type = gdk_eventkey.state
      modifiers = []
      modifiers << :control if gdk_modifier_type.control_mask?
      modifiers << :alt     if gdk_modifier_type.mod1_mask?
      modifiers << :caps    if gdk_modifier_type.lock_mask?
      modifiers << :shift   if gdk_modifier_type.shift_mask?
      modifiers << :super   if gdk_modifier_type.mod4_mask?
      
      KeyStroke.new(modifiers, keyname)
    end
    
    def issue_from_gdk_eventkey(gdk_eventkey)
      issue_from_keystroke(gdk_eventkey_to_keystroke(gdk_eventkey))
    end
  end
end
