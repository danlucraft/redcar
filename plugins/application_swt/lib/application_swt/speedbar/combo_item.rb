module Redcar
  class ApplicationSWT
    class Speedbar
      class ComboItem
        def initialize(composite, item)
          combo = Swt::Widgets::Combo.new(composite, Swt::SWT::READ_ONLY)
          combo.items = item.items.to_java(:string)
          if item.value
            combo.select(item.items.index(item.value))
          end
          combo.add_selection_listener do
            ignore(item.name) do
              item.value = combo.text
              execute_listener_in_model(item, item.value)
            end
          end
          item.add_listener(:changed_items) do |new_items|
            rescue_speedbar_errors do
              ignore(item.name) do
                combo.items = item.items.to_java(:string)
                item.value = nil
              end
            end
          end
          item.add_listener(:changed_value) do |new_value|
            rescue_speedbar_errors do
              ignore(item.name) do
                combo.select(item.items.index(item.value))
              end
            end
          end
          keyable_widgets    << combo
          focussable_widgets << combo
        end
      end
    end
  end
end
