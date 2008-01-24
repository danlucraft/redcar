

module Redcar
  module Plugins
    module Keymaps
      extend FreeBASE::StandardPlugin
      
      def self.load(plugin)
        Redcar::Keymap.set_standard_keymaps

        plugin.transition(FreeBASE::LOADED)
      end
      
      def self.start(plugin)
        plugin.transition(FreeBASE::RUNNING)
      end
    end
  end

  # A Keymap may be attached to any of the following with
  # Keymap#push_before
  # 1. Redcar.Keymap.Global
  # 2. Redcar.Keymap.Tab
  # 3. Any tab class
  # 4. Any tab instance
  # 5. Any Gtk widget class
  # 6. Any Gtk widget instance
  # If the correct keybinding is not found anywhere in this stack, the
  # key event will fall through to the current Gtk widget (if any), which
  # can deal with it or not.
  
  class Keymap
    GlobalPoint = :global
    TabPoint    = :tab
    
    def self.set_standard_keymaps
      # set up standard keymaps
      global_keymap = Redcar::Keymap.new("Application Wide")
      global_keymap.push_before(Redcar::Keymap::GlobalPoint)
      
      tab_keymap = Redcar::Keymap.new("Tab")
      tab_keymap.push_before(Redcar::Keymap::TabPoint)
    end

    @@keymaps = []
    @@stack = {}
    
    attr_accessor :name
    
    def initialize(name)
      @name = name
      @@keymaps << self
      @commands = {}
      @count = 0
    end
    
    def push_before(object)
      @@stack[object] ||= []
      @@stack[object] << self
    end
    
    def add_command(command)
      @count += 1
      arr = (@commands[KeyStroke.parse(command[:keybinding].to_s).to_s] ||= [])
      arr << command
    end
    
    def keystrokes
      @commands.keys
    end
    
    def contains?(keystroke)
      @commands[keystroke]
    end
    
    def execute_keystroke(keystroke)
      if candidates = @commands[keystroke.to_s]
        if candidates.length > 1
          menu_entries = candidates.map do |command|
            [nil, command.name, command.path]
          end
          $BUS['/redcar/services/context_menu_options_popup'].call(menu_entries)
          puts "candidates: #{candidates.map{|c| c.path}.inspect}"
        else
          command = candidates.first
          Command.execute(command)
          return true
        end
      end
    end
    
    def inspect
      "#<Keymap:\"#{@name}\" #{@count} commands>"
    end
    
    alias to_s inspect
    
    def self.clear
      @@stack = {}
      @@keymaps = []
    end
    
    def self.all
      @@keymaps
    end
    
    def self.[](name)
      @@keymaps.find{|km| km.name == name}
    end
    
    def self.load
      commands = Redcar.image.find_with_tags(:command)
      commands.each do |command|
        if command[:activated_by] == :key_combination or
            command[:activated_by] == nil
          keymap_name = command[:keymap]
          keymap_name = "Application Wide" unless keymap_name
          keymap = Redcar.Keymap[keymap_name]
          if keymap
            keymap.add_command(command)
          else
            puts "trying to load command into non-existent"+
              "keymap: #{keymap_name}"
          end
        end
      end
    end
    
    def self.execute_keystroke(keystroke)
      if execute_keystroke_on(:global, keystroke)
        return true
      end
      if tab = Redcar.current_tab
        if execute_keystroke_on(:tab, keystroke)
          return true
        end
        if execute_keystroke_on(tab.class, keystroke)
          return true
        end
        if execute_keystroke_on(tab, keystroke)
          return true
        end
      end
      if widget = Gtk.current
        if execute_keystroke_on(widget.class, keystroke)
          return true
        end
        if execute_keystroke_on(widget, keystroke)
          return true
        end
      end
      false
    end
    
    def self.execute_keystroke_on(object, keystroke)
      if object and @@stack[object]
        @@stack[object].reverse.each do |keymap|
          if keymap.contains? keystroke.to_s
            keymap.execute_keystroke keystroke
            return true
          end
        end
      end
      false
    end
  end
  
  class KeyStroke
    attr_reader :modifiers, :keyname
    def initialize(modifiers, keyname)
      @modifiers = modifiers.sort_by {|m| m.to_s }
      @keyname = keyname.upcase
    end
    
    def to_s
      if self.modifiers.length > 0
        str = self.modifiers.join('+')+"+"
      else
        str = ""
      end
      str+self.keyname.upcase
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
            :Alt
          when "control", "ctrl", "c"
            :Ctrl
          when "shift", "sh", "s"
            :Shift
          when "caps", "lock", "capslock", "cl"
            :Caps
          when "super", "sup", "spr", "sp"
            :Super
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
          # falls through to Gtk widget if nothing handles it
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
      modifiers << :Ctrl if gdk_modifier_type.control_mask?
      modifiers << :Alt     if gdk_modifier_type.mod1_mask?
      modifiers << :Caps    if gdk_modifier_type.lock_mask?
      modifiers << :Shift   if gdk_modifier_type.shift_mask?
      modifiers << :Super   if gdk_modifier_type.mod4_mask?
      
      ks = KeyStroke.new(modifiers, keyname)
    end
    
    def issue_from_gdk_eventkey(gdk_eventkey)
      issue_from_keystroke(gdk_eventkey_to_keystroke(gdk_eventkey))
    end
  end
end
