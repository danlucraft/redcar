
module Redcar
  # Encapsulates a Redcar command. Commands wrap a block of Ruby code
  # with additional metadata to deal with command history recording and
  # menus and keybindings. Define commands by subclassing the
  # Redcar::Command class.
  #
  # === Examples
  #
  #   class CloseTab < Redcar::Command
  #     menu "File/Close"
  #     key "Ctrl+W"
  #
  #     def execute
  #       tab.close if tab
  #     end
  #   end
  class Command
    include FreeBASE::DataBusHelper
    extend Redcar::CommandActivation
    
    class << self
      include Redcar::Sensitive
      attr_writer :name
    end
    
    def self.running
      @running ||= []
    end
    
    def self.set_command_running(command)
      @running ||= []
      @running << command
    end
    
    def self.set_command_stopped(command)
      @running.delete(command)
    end

    def self.load
      Range.active ||= []
    end

    def self.start #:nodoc:
      CommandHistory.clear
    end

    def self.stop #:nodoc:
      CommandHistory.clear
    end

    def self.inherited(klass)
      bus("/redcar/commands/#{klass}").data = klass
      @child_commands ||= []
      @child_commands << klass
#      puts ":inherited: #{klass} < #{self}"
      klass.update_operative
    end

    def self.child_commands
      @child_commands || []
    end
    
    def self.name
      return @name if @name
      to_s
    end

    def self.process_command_error(name, e)
      puts "* Error in command: #{name}"
      puts "  trace:"
      puts e.to_s
      puts e.backtrace
    end

    def self.menu=(menu)
      @menu = menu
    end

    def self.menu(menu)
      menu_path = menu.split("/").reverse
      top = menu_path.pop
      _menu = Menu.get_main(top)
      while portion = menu_path.pop and menu_path.any?
        _menu = _menu.get_submenu(portion)
      end
      _menu.add_item(portion, self)
      @menu = _menu
    end
    
    class << self
      attr_accessor :menu_item
    end

    def self.icon(icon)
      @icon = icon
    end

    def self.key(key)
      @key = key
      Redcar::Keymap.register_key_command(key, self)
    end

    # Set the documentation string for this Command.
    def self.doc(val)
      @doc = val
    end

    # Set the range for this Command.
    def self.range(val)
      @range = val
      Range.register_command(val, self)
      update_operative
    end

    def self.scope(scope)
      @scope = scope
    end

    def self.sensitive(sens)
      @sensitive ||= []
      @sensitive << sens
      Redcar::Sensitive.sensitize(self, sens)
    end

    def self.input(input)
      @input = input
    end

    def self.get(var)
      instance_variable_get("@#{var}")
    end

    def self.set(var, val)
      instance_variable_set("@#{var}", val)
    end

    def self.fallback_input(input)
      @fallback_input = input
    end

    def self.output(output)
      @output = output
    end

    def self.norecord
      @norecord = true
    end

    # If a command 'passes' it does nothing except allow the GTK+ event 
    # to continue propagating. This is useful when you do not want to reimplement
    # GTK+ functions (e.g. page up in a TextView) but you do want to record
    # the functions in the command history.
    def self.pass
      @pass = true
    end
    
    attr_accessor :gdk_event_key

    def tab
      @executor.tab
    end
    
    def doc
      @executor.doc
    end
    
    def view
      @executor.view
    end
    
    def win
      @executor.win
    end

    def do(opts={})
      @executor = Executor.new(self, opts)
      @executor.execute
    end
    
    def record?
      !self.class.norecord?
    end
    
    def to_s
      interesting_variables = instance_variables - %w(@__tab @__view @__doc @output)
      bits = interesting_variables.map do |iv|
        "#{iv}=" + instance_variable_get(iv.intern).inspect
      end
      self.class.to_s + " " + bits.join(", ")
    end
  end

  class ArbitraryCodeCommand < Command #:nodoc:
    norecord

    def initialize(&block)
      @block = block
    end

    def execute
      @block.call
    end
  end

end
