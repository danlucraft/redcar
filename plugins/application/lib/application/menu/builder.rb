module Redcar
  class Menu
    # A DSL for building menus simply. An example of usage
    #
    #     builder = Menu::Builder.new "Edit" do
    #       item "Select All", SelectAllCommand
    #       sub_menu "Indent" do
    #         item "Increase", IncreaseIndentCommand
    #         item "Decrease", DecreaseIndentCommand
    #       end
    #     end
    #
    # This is equivalent to:
    # 
    #     menu = Redcar::Menu.new("Edit")
    #     menu << Redcar::Menu::Item.new("Select All", SelectAllCommand)
    #     indent_menu = Redcar::Menu.new("Indent") 
    #     indent_menu << Redcar::Menu::Item.new("Increase", IncreaseIndentCommand)
    #     indent_menu << Redcar::Menu::Item.new("Decrease", DecreaseIndentCommand)
    #     menu << indent_menu
    class Builder
      attr_reader :menu
      
      def initialize(text=nil, &block)
        @menu = Redcar::Menu.new(text)
        @current_menu = @menu
        instance_eval(&block)
      end
      
      private
      
      def item(text, command)
        @current_menu << Item.new(text, command)
      end
      
      def separator
        @current_menu << Item::Separator.new
      end
      
      def sub_menu(text, &block)
        new_menu = Menu.new(text)
        @current_menu << new_menu
        old_menu, @current_menu = @current_menu, new_menu
        instance_eval(&block)
        @current_menu = old_menu
      end
    end
  end
end