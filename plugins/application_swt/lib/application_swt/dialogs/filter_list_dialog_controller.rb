module Redcar
  class ApplicationSWT
    class FilterListDialogController
      class FilterListDialog < Dialogs::NoButtonsDialog
        attr_reader :list
        attr_accessor :controller
        
        def createDialogArea(parent)
          composite = Swt::Widgets::Composite.new(parent, Swt::SWT::NONE)
          layout = Swt::Layout::RowLayout.new(Swt::SWT::VERTICAL)
          composite.setLayout(layout)

          @text = Swt::Widgets::Text.new(composite, Swt::SWT::SINGLE | Swt::SWT::LEFT | Swt::SWT::ICON_CANCEL)
          @text.set_layout_data(Swt::Layout::RowData.new(400, 20))
          @list = Swt::Widgets::List.new(composite, Swt::SWT::SINGLE)
          @list.set_layout_data(Swt::Layout::RowData.new(400, 200))
          attach_listeners
          controller.populate_starting_list
          @list.set_selection(0)
        end
        
        def attach_listeners
          @text.add_modify_listener do
            text = @text.get_text
            controller.text_changed(text)
          end
          @text.add_key_listener do |key_event|
            case key_event.keyCode
            when Swt::SWT::CR, Swt::SWT::LF
              controller.selected
            end
          end
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
        @dialog = FilterListDialog.new(Redcar.app.focussed_window.controller.shell)
        @dialog.controller = self
        @dialog.open
        @dialog = nil
      end
      
      def populate_starting_list
        populate_list(@model.starting_list)
      end
      
      def text_changed(new_text)
        populate_list(@model.update_list(new_text))
        @dialog.list.set_selection(0)
      end
      
      def selected
        @model.selected(@dialog.list.get_selection.first)
      end
      
      private
      
      def populate_list(contents)
        @dialog.list.removeAll
        contents.each do |text|
          @dialog.list.add(text)
        end
      end
    end
  end
end