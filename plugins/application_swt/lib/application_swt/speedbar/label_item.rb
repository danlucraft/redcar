module Redcar
  class ApplicationSWT
    class Speedbar
      class LabelItem
        def initialize(speedbar, composite, item)
          label = Swt::Widgets::Label.new(composite, 0)
          label.set_text(item.text)
          item.add_listener(:changed_text) do |new_text|
            label.set_text(item.text)
          end
        end
      end
    end
  end
end
