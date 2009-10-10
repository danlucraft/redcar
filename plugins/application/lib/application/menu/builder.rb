module Redcar
  class Menu
    # A DSL for building menus simply. An example of usage
    #
    #   builder = Menu::Builder.new do
    #     sub_menu "File" do
    #       item "New", NewCommand
    #     end
    #     sub_menu "Help" do
    #       item "Website", WebsiteCommand
    #     end
    #   end
    #
    # This is equivalent to:
    # 
    #   menu = Redcar::Menu.new
    #   file_menu = Redcar::Menu.new("File") 
    #   help_menu = Redcar::Menu.new("Help")
    #   menu << file_menu
    #   menu << help_menu
    #   file_menu << Redcar::Menu::Item.new("New", NewCommand)
    #   help_menu << Redcar::Menu::Item.new("Website", WebsiteCommand)
    class Builder
      attr_reader :menu
      
      def initialize(&block)
        @menu = Redcar::Menu.new
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