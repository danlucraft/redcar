module Redcar
  class ApplicationSWT
    class Menu
      attr_reader :menu_bar
      
      def initialize(window, menu_model)
        @menu_bar = Swt::Widgets::Menu.new(window.shell, Swt::SWT::BAR)
        return unless menu_model
        menu_model.each do |entry|
          menuHeader = Swt::Widgets::MenuItem.new(@menu_bar, Swt::SWT::CASCADE)
          menuHeader.text = entry.text
          menu = Swt::Widgets::Menu.new(window.shell, Swt::SWT::DROP_DOWN)
          menuHeader.setMenu(menu)
        end
      end
    end
  end
end