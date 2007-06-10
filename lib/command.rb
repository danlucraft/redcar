
module Redcar
  
  def self.process_command_error(name, e)
    puts "* Error in user command: #{name}"
    puts "  trace:"
    puts e.to_s
    puts e.backtrace
  end
  
  module Keymap
    def Keymap.get_keymap(keybinding)
      if Redcar.GlobalKeymap.keymap_respond_to?(keybinding)
        return Redcar.GlobalKeymap
      else
        focussed_keymap = find_focussed_keymap
        if focussed_keymap and 
            focussed_keymap.keymap_respond_to?(keybinding)
          return focussed_keymap
        end
      end
    end
    
    def Keymap.find_focussed_keymap
      focussed_object = Redcar.current_window.focus
      ObjectSpace.each_object(Redcar::Keymap) do |obj|
        if obj.respond_to? :widget
          if obj.widget == focussed_object
            return obj
          end
        elsif obj.respond_to? :widgets
          if obj.widgets.include? focussed_object
            return obj
          end
        end
      end
      nil
    end
    
    def Keymap.find_all_keymaps(keybinding)
      keymaps = []
      ObjectSpace.each_object(Redcar::Keymap) do |obj|
        if obj.respond_to? :keymap_respond_to?
          if obj.keymap_respond_to? keybinding
            keymaps << obj
          end
        end
      end
      keymaps
    end
    
    def Keymap.append_features(dest_class)
      def dest_class.keymap(keybinding, func_name, *args)
        @map ||= {}
        unless keybinding.is_a? Regexp
          keybinding = KeyBinding.parse(keybinding).to_s
        end
        @map[keybinding] = [func_name, args]
      end
      
      def dest_class.get_keymap_this(keybinding)
        t = @map[keybinding]
        return t if t
        @map.keys.select{|r| r.is_a? Regexp}.each do |rx|
          if keybinding =~ rx
            result = @map[rx].clone
            result[1] = result[1].clone
            result[1][0] = result[1][0].gsub('\1', $1)
            return result
          end
        end
        nil
      end
      
      def dest_class.get_keymap(keybinding)
        @map ||= {}
        keybinding = KeyBinding.parse(keybinding).to_s
        self.ancestors.each do |thisclass|
          if thisclass.respond_to? :get_keymap_this
            km = thisclass.get_keymap_this(keybinding)
            return km if km
          end
        end
        nil
      end
      
      def dest_class.keymap_respond_to?(keybinding)
        puts keybinding
        a, b = get_keymap(keybinding)
        a
      end
      
      def dest_class.start_commands
        @should_add = true
      end
      
      def dest_class.end_commands
        @should_add = false
      end
      
      def dest_class.user_commands(&block)
        @should_add = true
        self.class_eval(&block)
        @should_add = false
      end
      
      def dest_class.method_added(meth)
        unless @adding
          if @should_add
            @adding = true
            self.class_eval do
              alias_method "__base_#{meth}", "#{meth}"
              define_method(meth) do |*args|
                unless defined? @recording
                  @recording = true
                end
                add_to_command_history([meth, args]) if @recording
                #puts "#{meth} called, recording:#{@recording.to_s}. Params = #{args.inspect}"
                was_on = @recording
                @recording = false
                result = nil
                begin
                  undoable do
                    result = self.send("__base_#{meth}", *args)
                  end
                rescue Object => e
                  Redcar.process_command_error(meth, e)
                end
                @recording = was_on
                result
              end
            end
            @adding = false
          end
        end
      end
      
      super
    end
    
    def command_history
      @command_history
    end
    
    def clear_command_history
      @command_history = []
    end
    
    def add_to_command_history(command)
      @command_history ||= []
      @command_history << command
    end
    
    def get_keymap(keybinding)
      self.class.get_keymap(keybinding)
    end
    
    def keymap_respond_to?(keybinding)
      a, b = self.class.get_keymap(keybinding)
      a
    end
    
    def execute_key(keybinding)
      Redcar.event :keystroke, keybinding
      method_name, method_args = self.class.get_keymap(keybinding)
      begin
        self.send(method_name, *method_args)
        #         rescue Object => ex
        #           Redcar.StatusBar.main = "command failed: #{method_name}(#{method_args.join(", ")}) [#{ex}]"
      end
    end
  end        

  def self.GlobalKeymap
    @@gbkm ||= GlobalKeymap.new
  end

  class GlobalKeymap
    include Keymap
  end
    
  class KeyBinding
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
      other = KeyBinding.parse(other)
      self.keyname == other.keyname and
        self.modifiers == other.modifiers
    end
    
    def self.parse(str)
      return str if str.is_a? KeyBinding
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
  
  class Keystrokes
    attr_reader :history_size, :history
    def initialize(options={})
      options = process_params(options,
                               { :history => 500 })
      @history_size = options[:history]
      @history = []
    end
    
    def add_to_history(keybinding)
      keybinding = KeyBinding.parse(keybinding)
      @history << keybinding
      if @history.length == @history_size
        @history = @history[1..-1]
      end
    end

    def clear_history
      @history = []
    end
    
    def issue(kb)
      issue_from_keybinding(kb)
    end
    
    def issue_from_keybinding(keybinding)
      keybinding = KeyBinding.parse(keybinding)
      keymap = Keymap.get_keymap(keybinding)
      if keymap
        add_to_history(keybinding)
        keymap.execute_key keybinding
      end
    end
    
    def issue_from_gdk_eventkey(gdk_eventkey)
      keyname = " "
      keyname[0] = Gdk::Keyval.to_unicode(gdk_eventkey.keyval)
      keyname = Gdk::Keyval.to_name(gdk_eventkey.keyval) if keyname=="\000"
      p keyname
      gdk_modifier_type = gdk_eventkey.state
      modifiers = []
      modifiers << :control if gdk_modifier_type.control_mask?
      modifiers << :alt     if gdk_modifier_type.mod1_mask?
      modifiers << :caps    if gdk_modifier_type.lock_mask?
      modifiers << :shift   if gdk_modifier_type.shift_mask?
      modifiers << :super   if gdk_modifier_type.mod4_mask?
      
      keybinding = KeyBinding.new(modifiers, keyname)
      issue_from_keybinding(keybinding)
    end
  end
end
