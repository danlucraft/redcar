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
            item = Swt::Widgets::MenuItem.new(menu, Swt::SWT::PUSH)
            if entry.command.get_key
              key_specifier = entry.command.get_key
              key_string    = BindingTranslator.platform_key_string(key_specifier)
              item.text = entry.text + "\t" + key_string
              item.set_accelerator(BindingTranslator.key(key_string))
            else
              item.text = entry.text
            end
            item.addSelectionListener do
              puts "#{entry.command} activated"
              entry.selected
            end
            entry.command.add_listener(:active_changed) do |value|
              item.enabled = value
            end
            if not entry.command.active?
              item.enabled = false
            end
          end
        end
      end
    end
  end
end
