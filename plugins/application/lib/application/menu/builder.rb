
module Redcar
  class Menu
    # A DSL for building menus simply. An example of usage
    #
    #     builder = Menu::Builder.new "Edit" do
    #       item "Select All", SelectAllCommand
    #       sub_menu "Indent" do
    #         item "Increase", IncreaseIndentCommand
    #         item("Decrease") { puts "decrease selected" }
    #       end
    #     end
    #
    # This is equivalent to:
    # 
    #     menu = Redcar::Menu.new("Edit")
    #     menu << Redcar::Menu::Item.new("Select All", SelectAllCommand)
    #     indent_menu = Redcar::Menu.new("Indent") 
    #     indent_menu << Redcar::Menu::Item.new("Increase", IncreaseIndentCommand)
    #     indent_menu << Redcar::Menu::Item.new("Decrease") do
    #       puts "decrease selected"
    #     end
    #     menu << indent_menu
    class Builder
      attr_reader :menu
      
      def self.build(name=nil, &block)
        new(name, &block).menu
      end
      
      def initialize(menu_or_text=nil, &block)
        case menu_or_text
        when String, nil
          @menu = Redcar::Menu.new(menu_or_text||"")
        when Menu
          @menu = menu_or_text
        end
        @current_menu = @menu
        if block.arity == 1
          block.call(self)
        else
          instance_eval(&block)
        end
      end
      
      def item(text, options={}, &block)
        @current_menu << Item.new(text, options, &block)
      end
      
      def separator(options={})
        @current_menu << Item::Separator.new(options)
      end
      
      def sub_menu(text, options={}, &block)
        new_menu = Menu.new(text, options)
        @current_menu << new_menu
        old_menu, @current_menu = @current_menu, new_menu
        if block.arity == 1
          block.call(self)
        else
          instance_eval(&block)
        end
        @current_menu = old_menu
      end
      
      def lazy_sub_menu(text, options={}, &block)
        new_menu = LazyMenu.new(block, text, options)
        @current_menu << new_menu
      end
      
      def group(options={}, &block)
        Builder::Group.new(self, options, &block)
      end
      
      def append(item)
        @current_menu << item
      end
    end
  end
end
