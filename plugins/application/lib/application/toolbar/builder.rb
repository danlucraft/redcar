
module Redcar
  class Toolbar
    # A DSL for building toolbars simply. An example of usage
    #
    #     builder = Toolbar::Builder.new "Edit" do
    #       item "Select All", SelectAllCommand
    #       sub_toolbar "Indent" do
    #         item "Increase", IncreaseIndentCommand
    #         item("Decrease") { puts "decrease selected" }
    #       end
    #     end
    #
    # This is equivalent to:
    # 
    #     toolbar = Redcar::Toolbar.new("Edit")
    #     toolbar << Redcar::Toolbar::Item.new("Select All", SelectAllCommand)
    #     indent_toolbar = Redcar::Toolbar.new("Indent") 
    #     indent_toolbar << Redcar::Toolbar::Item.new("Increase", IncreaseIndentCommand)
    #     indent_toolbar << Redcar::Toolbar::Item.new("Decrease") do
    #       puts "decrease selected"
    #     end
    #     toolbar << indent_toolbar
    class Builder
      attr_reader :toolbar
      
      def self.build(name=nil, &block)
        new(name, &block).toolbar
      end
      
      def initialize(toolbar_or_text=nil, &block)
        case toolbar_or_text
        when String, nil
          @toolbar = Redcar::Toolbar.new(toolbar_or_text||"")
        when Toolbar
          @toolbar = toolbar_or_text
        end
        @current_toolbar = @toolbar
        if block.arity == 1
          block.call(self)
        else
          instance_eval(&block)
        end
      end
      
      def item(text, options={}, &block)
        @current_toolbar << Item.new(text, options, &block)
      end
      
      def separator(options={})
        @current_toolbar << Item::Separator.new(options)
      end
      
      def sub_toolbar(text, options={}, &block)
        new_toolbar = Toolbar.new(text, options)
        @current_toolbar << new_toolbar
        old_toolbar, @current_toolbar = @current_toolbar, new_toolbar
        if block.arity == 1
          block.call(self)
        else
          instance_eval(&block)
        end
        @current_toolbar = old_toolbar
      end
      
      def lazy_sub_toolbar(text, options={}, &block)
        new_toolbar = LazyToolbar.new(block, text, options)
        @current_toolbar << new_toolbar
      end
      
      def group(options={}, &block)
        Builder::Group.new(self, options, &block)
      end
      
      def append(item)
        @current_toolbar << item
      end
    end
  end
end
