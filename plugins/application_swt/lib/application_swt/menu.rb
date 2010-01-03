module Redcar
  class ApplicationSWT
    class Menu
      attr_reader :menu_bar
      
      def initialize(window, menu_model)
        @window = window
        @menu_bar = Swt::Widgets::Menu.new(window.shell, Swt::SWT::BAR)
        return unless menu_model
        @handlers = []
        add_entries_to_menu(@menu_bar, menu_model)
      end
      
      def close
        @handlers.each {|obj, h| obj.remove_listener(h)}
        @menu_bar.dispose
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
          elsif entry.is_a?(Redcar::Menu::Item::Separator)
            item = Swt::Widgets::MenuItem.new(menu, Swt::SWT::SEPARATOR)
          elsif entry.is_a?(Redcar::Menu::Item)
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
            h = entry.command.add_listener(:active_changed) do |value|
              unless item.disposed
                item.enabled = value
              end
            end
            @handlers << [entry.command, h]
            if not entry.command.active?
              item.enabled = false
            end
          else
            raise "unknown object of type #{entry.class} in menu"
          end
        end
      end
    end
  end
end
