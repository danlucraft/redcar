module Redcar
  class ApplicationSWT
    class Speedbar
      class SliderItem
        def initialize(speedbar, composite, item)
          slider = Swt::Widgets::Slider.new(composite, Swt::SWT::HORIZONTAL)
          grid_data = Swt::Layout::GridData.new
          grid_data.grabExcessHorizontalSpace = true
          grid_data.horizontalAlignment = Swt::Layout::GridData::FILL
          slider.layout_data = grid_data
          slider.selection = item.value
          slider.maximum   = item.maximum   || 100
          slider.minimum   = item.minimum   || 0
          slider.increment = item.increment || 5
          slider.add_selection_listener do
            item.value = slider.selection
            speedbar.execute_listener_in_model(item, item.value)
          end
          [:minimum, :maximum, :increment, :enabled].each do |ivar|
            item.add_listener(:"changed_#{ivar}") do |new_value|
              speedbar.rescue_speedbar_errors { slider.send(:"#{ivar}=", new_value) }
            end
          end
          item.add_listener(:changed_value) do |new_value|
            speedbar.rescue_speedbar_errors { slider.selection = new_value }
          end
          speedbar.focussable_widgets << slider
        end
      end
    end
  end
end
