module Redcar
  class ApplicationSWT
    class FilterListDialogController
      class FilterListDialog < Dialogs::NoButtonsDialog
        attr_reader :list
        attr_accessor :controller
        
        def createDialogArea(parent)
          composite = Swt::Widgets::Composite.new(parent, Swt::SWT::NONE)
          layout = Swt::Layout::RowLayout.new(Swt::SWT::VERTICAL)
        #  layout.marginHeight = 0
        ##  layout.marginWidth = 0
        #  layout.verticalSpacing = 0
          composite.setLayout(layout)

          @text = Swt::Widgets::Text.new(composite, Swt::SWT::SINGLE | Swt::SWT::LEFT | Swt::SWT::ICON_CANCEL)
          @text.set_layout_data(Swt::Layout::RowData.new(400, 20))
          @list = Swt::Widgets::List.new(composite, Swt::SWT::SINGLE)
          @list.set_layout_data(Swt::Layout::RowData.new(400, 200))
          @list.add("fpp")
          @list.add("fp2")
          @list.add("f4p")
          @list.add("6pp")
        end
      end
      
      def initialize(model)
        @model = model
        attach_listeners
      end
      
      def attach_listeners
        @model.add_listener(:open, &method(:open))
      end
      
      def open
        dialog = FilterListDialog.new(Redcar.app.focussed_window.controller.shell)
        dialog.controller = self
        dialog.open
      end
    end
  end
end