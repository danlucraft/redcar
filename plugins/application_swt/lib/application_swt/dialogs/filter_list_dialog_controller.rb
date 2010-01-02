module Redcar
  class ApplicationSWT
    class FilterListDialogController
      class FilterListDialog < Dialogs::NoButtonsDialog
        def createDialogArea(parent)
          button = Swt::Widgets::Button.new(parent,Swt::SWT::PUSH)
          button.setText("Button in dialog")
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
        dialog.open
      end
    end
  end
end