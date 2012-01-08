
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
      def initialize(text, options={}, &block)
        @text = text
        
        if options.respond_to?('[]')
          @command = options[:command] || block
          @priority = options[:priority]
          @value = options[:value]
          @type = options[:type]
          if [:check, :radio].include?(@type)
            @checked = options[:checked]
          end
        else
          @command = options || block
        end
        
        @priority ||= Menu::DEFAULT_PRIORITY
      end
      
      # Call this to signal that the menu item has been selected by the user.
      def selected(with_key=false)
        if @value
          @command.new.run(:value => @value)
        else  
          @command.new.run#(:with_key => with_key)
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
