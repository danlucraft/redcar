module Redcar
  class ApplicationSWT
    class Speedbar
      attr_reader :widget
      
      def initialize(window, model)
        @window = window
        @model = model
        create_widget
      end
      
      def create_widget
        composite = Swt::Widgets::Composite.new(@window.shell, Swt::SWT::NONE)
        layout = Swt::Layout::RowLayout.new(Swt::SWT::HORIZONTAL)
        composite.setLayout(layout)

        @model.items.each do |item|
          case item
          when Redcar::Speedbar::LabelItem
            p :foo
          end
        end
#        @text = Swt::Widgets::Text.new(composite, Swt::SWT::SINGLE | Swt::SWT::LEFT | Swt::SWT::ICON_CANCEL)
#        @text.set_layout_data(Swt::Layout::RowData.new(400, 20))
#        @list = Swt::Widgets::List.new(composite, Swt::SWT::SINGLE)
#        @list.set_layout_data(Swt::Layout::RowData.new(400, 200))
      end
      
    end
  end
end