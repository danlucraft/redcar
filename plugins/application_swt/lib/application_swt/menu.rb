module Redcar
  class ApplicationSWT
    class Menu
      attr_reader :menu_bar
      
      def initialize(window, menu_model)
        @window = window
        @menu_bar = Swt::Widgets::Menu.new(window.shell, Swt::SWT::BAR)
        return unless menu_model
        add_entries_to_menu(@menu_bar, menu_model)
      end
      
      private
      
      def add_entries_to_menu(menu, menu_model)
        menu_model.each do |entry|
          if entry.is_a?(Redcar::Menu)
            menu_header = Swt::Widgets::MenuItem.new(menu, Swt::SWT::CASCADE)
            menu_header.text = entry.text
            new_menu = Swt::Widgets::Menu.new(@window.shell, Swt::SWT::DROP_DOWN)
            menu_header.menu = new_menu
            add_entries_to_menu(new_menu, entry)
          else
            menu_header = Swt::Widgets::MenuItem.new(menu, Swt::SWT::PUSH)
            menu_header.text = entry.text
          end
        end
      end
    end
  end
end