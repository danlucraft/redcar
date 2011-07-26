module Redcar
  class ApplicationSWT
    class Speedbar
      class ComboItem
        def initialize(speedbar, composite, item)
          if @editable = item.editable
            type = Swt::SWT::DROP_DOWN
          else
            type = Swt::SWT::READ_ONLY
          end
          combo = Swt::Widgets::Combo.new(composite, type)
          combo.items = item.items.to_java(:string)
          if @editable
            combo.set_text(item.value || "")
            combo.add_modify_listener do
              speedbar.ignore(item.name) do
                item.value = combo.text
                speedbar.execute_listener_in_model(item, item.value)
              end
            end
          else
            combo.select(item.items.index(item.value)) if item.value
          end
          combo.add_selection_listener do
            speedbar.ignore(item.name) do
              item.value = combo.text
              speedbar.execute_listener_in_model(item, item.value)
            end
          end
          item.add_listener(:changed_items) do |new_items|
            speedbar.rescue_speedbar_errors do
              speedbar.ignore(item.name) do
                combo.items = item.items.to_java(:string)
                item.value = @editable ? "" : nil
              end
            end
          end
          item.add_listener(:changed_value) do |new_value|
            speedbar.rescue_speedbar_errors do
              speedbar.ignore(item.name) do
                if @editable
                  combo.set_text(item.value)
                else
                  combo.select(item.items.index(item.value))
                end
              end
            end
          end
          speedbar.keyable_widgets    << combo
          speedbar.focussable_widgets << combo
        end
      end
    end
  end
end
