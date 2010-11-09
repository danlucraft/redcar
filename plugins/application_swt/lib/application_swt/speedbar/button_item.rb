module Redcar
  class ApplicationSWT
    class Speedbar
      class ButtonItem
        def initialize(speedbar, composite, item)
          button = Swt::Widgets::Button.new(composite, 0)
          button.set_text(item.text)
          button.add_selection_listener do
            speedbar.execute_listener_in_model(item)
          end
          item.add_listener(:changed_text) do |new_text|
            button.set_text(item.text)
          end
          speedbar.keyable_widgets << button
          speedbar.focussable_widgets << button
        end
      end
    end
  end
end
