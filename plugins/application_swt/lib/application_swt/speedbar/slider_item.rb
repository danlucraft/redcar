module Redcar
  class ApplicationSWT
    class Speedbar
      class SliderItem
        def initialize(composite, item)
          slider = Swt::Widgets::Slider.new(composite, Swt::SWT::HORIZONTAL)
          slider.selection = item.value
          slider.maximum   = item.maximum   || 100
          slider.minimum   = item.minimum   || 0
          slider.increment = item.increment || 5
          slider.add_selection_listener do
            item.value = slider.selection
            execute_listener_in_model(item, item.value)
          end
          [:value, :minimum, :maximum, :increment, :enabled].each do |ivar|
            item.add_listener(:"changed_#{ivar}") do |new_value|
              rescue_speedbar_errors { slider.send(:"#{ivar}=", new_value) }
            end
          end
          focussable_widgets << slider
        end
      end
    end
  end
end
