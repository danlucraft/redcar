module Redcar
  class ApplicationSWT
    class FilterListDialogController
      class FilterListDialog < Dialogs::NoButtonsDialog
        attr_reader :list, :text
        attr_accessor :controller
        
        def createDialogArea(parent)
          composite = Swt::Widgets::Composite.new(parent, Swt::SWT::NONE)
          layout = Swt::Layout::RowLayout.new(Swt::SWT::VERTICAL)
          composite.setLayout(layout)

          @text = Swt::Widgets::Text.new(composite, Swt::SWT::SINGLE | Swt::SWT::LEFT | Swt::SWT::ICON_CANCEL)
          @text.set_layout_data(Swt::Layout::RowData.new(400, 20))
          @list = Swt::Widgets::List.new(composite, Swt::SWT::SINGLE)
          @list.set_layout_data(Swt::Layout::RowData.new(400, 200))
          controller.attach_listeners
          controller.update_list
          @list.set_selection(0)
        end
      end
      
          
      def self.storage
        @storage ||= begin
          storage = Plugin::Storage.new('filter_list_dialog_controller')
          storage.set_default('pause_before_update_seconds', 0.25)
          storage
        end
      end    
      
      def initialize(model)
        @model = model
        @dialog = FilterListDialog.new(Redcar.app.focussed_window.controller.shell)
        @dialog.controller = self
        attach_model_listeners
      end
      
      def attach_model_listeners
        @model.add_listener(:open, &method(:open))
        @model.add_listener(:close, &method(:close))
      end

      class ModifyListener
        def initialize(controller)
          @controller = controller
        end
        
        def modify_text(e)
          @controller.update_list
        end
      end
      
      class KeyListener
        def initialize(controller)
          @controller = controller
        end
        
        def key_pressed(e)
          e.doit = @controller.key_pressed(e)
        end
        
        def key_released(e)
        end
      end
      
      def attach_listeners
        @dialog.text.add_modify_listener(ModifyListener.new(self))
        @dialog.text.add_key_listener(KeyListener.new(self))
      end
      
      def open
        @dialog.open
        @dialog = nil
      end
      
      def close
        @dialog.close
      end
      
      def update_list
        @last_keypress = Time.now
        pause_time = FilterListDialogController.storage['pause_before_update_seconds']
        Swt::Widgets::Display.getCurrent.timerExec(pause_time*1000, Swt::RRunnable.new { 
          if @dialog and @last_keypress and (Time.now - @last_keypress + pause_time) > pause_time
            @last_keypress = nil
            s = Time.now
            list = @model.update_list(@dialog.text.get_text)
            puts "update list took #{Time.now - s}s"
            populate_list(list)
            @dialog.list.set_selection(0)
          end
        })
      end
      
      def selected
        @model.selected(@dialog.list.get_selection.first, @dialog.list.get_selection_index)
      end
      
      def key_pressed(key_event)
        case key_event.keyCode
        when Swt::SWT::CR, Swt::SWT::LF
          selected
          false
        when Swt::SWT::ARROW_DOWN
          move_down
          false
        when Swt::SWT::ARROW_UP
          move_up
          false
        else
          true
        end
      end
      
      def move_down
        curr_ix = @dialog.list.get_selection_index
        new_ix = [curr_ix + 1, @dialog.list.get_item_count - 1].min
        @dialog.list.set_selection(new_ix)
      end
      
      def move_up
        curr_ix = @dialog.list.get_selection_index
        new_ix = [curr_ix - 1, 0].max
        @dialog.list.set_selection(new_ix)
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