
module Redcar
  class Menu
    class Item
      class Separator < Item
        def initialize(options={})
          super(nil, options)
        end
        
        def is_unique?
          true
        end
      end
      
      attr_reader :command, :priority, :value, :type
  
      # Create a new Item, with the given text to display in the menu, and
      # either:
      #   the Redcar::Command that is run when the item is selected.
      #   or a block to run when the item is selected
      #
      # Instead of a command, a hash of options may be passed:
      #  :command  - specify a command class
      #  :priority - Integer, higher means lower in menus
      #  :value    - if passed, the command class with be instantiation like:
      #              Command.new(:value => value)
      #  :enabled  - if set to false, this menu item will be permanently disabled
      #  :type     - can be set to :check or :radio
      #  :checked  - if type is check or radio, a block that will be run when 
      #              the menu is displayed to determine whether this item is checked
      def initialize(text, command_or_options={}, &block)
        @text = text
        
        if command_or_options.respond_to?('[]')
          options = command_or_options
          @command = options[:command] || block
          @priority = options[:priority]
          @value = options[:value]
          @type = options[:type]
          @enabled = (options.key?(:enabled) ? options[:enabled] : true)
          if [:check, :radio].include?(@type)
            @checked = options[:checked]
          end
        else
          @enabled = true
          @command = command_or_options || block
        end
        
        @priority ||= Menu::DEFAULT_PRIORITY
      end
      
      # Call this to signal that the menu item has been selected by the user.
      def selected(with_key=false)
        if @value
          @command.new.run(:value => @value)
        else  
          @command.new.run
        end
      end
      
      def type
        @type
      end
      
      def type
        @type
      end
      
      def text
        @text.respond_to?(:call) ? 
          Redcar::Application::GlobalState.new.instance_eval(&@text) :
          @text
      end
      
      def lazy_text?
        @text.respond_to?(:call)
      end
      
      def merge(other)
        @command = other.command
        @priority = other.priority
      end
      
      def ==(other)
        text == other.text and command == other.command
      end
      
      def is_unique?
        false
      end
      
      def enabled?
        @enabled
      end
      
      def checked?
        @checked and (
          @checked.respond_to?(:call) ?
            Redcar::Application::GlobalState.new.instance_eval(&@checked) :
            @checked
        )
      end
    end
  end
end
