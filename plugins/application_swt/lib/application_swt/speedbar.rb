module Redcar
  class ApplicationSWT
    class Speedbar
      attr_reader :widget
      
      def initialize(parent, model)
        @parent = parent
        @model = model
        create_widget
      end
      
      def create_widget
        composite = Swt::Widgets::Composite.new(@parent, Swt::SWT::NONE)
        layout = Swt::Layout::RowLayout.new(Swt::SWT::HORIZONTAL)
        composite.setLayout(layout)

        @model.items.each do |item|
          case item
          when Redcar::Speedbar::LabelItem
            label = Swt::Widgets::Label.new(composite, 0)
            label.set_text(item.text)
          end
        end
        @parent.layout
#        @text = Swt::Widgets::Text.new(composite, Swt::SWT::SINGLE | Swt::SWT::LEFT | Swt::SWT::ICON_CANCEL)
#        @text.set_layout_data(Swt::Layout::RowData.new(400, 20))
#        @list = Swt::Widgets::List.new(composite, Swt::SWT::SINGLE)
#        @list.set_layout_data(Swt::Layout::RowData.new(400, 200))
      end
      
    end
  end
end