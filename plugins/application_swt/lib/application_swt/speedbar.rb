module Redcar
  class ApplicationSWT
    class Speedbar
      attr_reader :widget
      
      def initialize(parent, model)
        @parent = parent
        @model = model
        create_widget
      end
      
      def num_columns
        @model.items.select {|i| !i.is_a?(Redcar::Speedbar::KeyItem) }.length
      end
      
      def create_widget
        composite = Swt::Widgets::Composite.new(@parent, Swt::SWT::NONE)
        grid_data = Swt::Layout::GridData.new
        grid_data.grabExcessHorizontalSpace = true
        grid_data.horizontalAlignment = Swt::Layout::GridData::FILL
      	composite.setLayoutData(grid_data)
        layout = Swt::Layout::GridLayout.new(num_columns, false)
        composite.setLayout(layout)

        @model.items.each do |item|
          case item
          when Redcar::Speedbar::LabelItem
            label = Swt::Widgets::Label.new(composite, 0)
            label.set_text(item.text)
          when Redcar::Speedbar::TextBoxItem
            textbox = Swt::Widgets::Text.new(composite, Swt::SWT::BORDER)
            textbox.set_text(item.value)
            gridData = Swt::Layout::GridData.new
            gridData.grabExcessHorizontalSpace = true
            gridData.horizontalAlignment = Swt::Layout::GridData::FILL
            textbox.set_layout_data(gridData)
            if item.listener
              textbox.add_modify_listener do
                item.value = textbox.get_text
                item.listener[item.value]
              end
            end
          when Redcar::Speedbar::ButtonItem
            button = Swt::Widgets::Button.new(composite, 0)
            button.set_text(item.text)
            if item.listener
              button.add_selection_listener do
                item.listener[]
              end
            end
          when Redcar::Speedbar::ToggleItem
            button = Swt::Widgets::Button.new(composite, Swt::SWT::CHECK)
            button.set_text(item.text)
            if item.listener
              button.add_selection_listener do
                item.value = button.get_selection
                item.listener[item.value]
              end
            end
          end
        end
        @parent.layout
      end
      
    end
  end
end