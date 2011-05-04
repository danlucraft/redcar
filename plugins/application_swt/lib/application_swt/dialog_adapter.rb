module Redcar
  class ApplicationSWT
    class DialogAdapter
      def open_file(options)
        file_dialog(Swt::SWT::OPEN, options)
      end

      def open_directory(options)
        directory_dialog(options)
      end

      def save_file(options)
        file_dialog(Swt::SWT::SAVE, options)
      end

      MESSAGE_BOX_TYPES = {
        :info     => Swt::SWT::ICON_INFORMATION,
        :error    => Swt::SWT::ICON_ERROR,
        :question => Swt::SWT::ICON_QUESTION,
        :warning  => Swt::SWT::ICON_WARNING,
        :working  => Swt::SWT::ICON_WORKING
      }

      BUTTONS = {
        :yes    => Swt::SWT::YES,
        :no     => Swt::SWT::NO,
        :cancel => Swt::SWT::CANCEL,
        :retry  => Swt::SWT::RETRY,
        :ok     => Swt::SWT::OK,
        :abort  => Swt::SWT::ABORT,
        :ignore => Swt::SWT::IGNORE
      }

      MESSAGE_BOX_BUTTON_COMBOS = {
        :ok                 => [:ok],
        :ok_cancel          => [:ok, :cancel],
        :yes_no             => [:yes, :no],
        :yes_no_cancel      => [:yes, :no, :cancel],
        :retry_cancel       => [:retry, :cancel],
        :abort_retry_ignore => [:abort, :retry, :ignore]
      }

      def message_box(text, options)
        styles = 0
        styles = styles | MESSAGE_BOX_TYPES[options[:type]] if options[:type]
        if options[:buttons]
          buttons = MESSAGE_BOX_BUTTON_COMBOS[options[:buttons]]
          buttons.each {|b| styles = styles | BUTTONS[b] }
        end
        dialog = Swt::Widgets::MessageBox.new(parent_shell, styles)
        dialog.set_message(text)
        result = nil
        Redcar.app.protect_application_focus do
          EditView.protect_edit_view_focus do
            result = dialog.open
          end
        end
        BUTTONS.invert[result]
      end

      def buttons
        BUTTONS.keys
      end

      def available_message_box_types
        MESSAGE_BOX_TYPES.keys
      end

      def available_message_box_button_combos
        MESSAGE_BOX_BUTTON_COMBOS.keys
      end

      def input(title, message, initial_value, &block)
        dialog = Dialogs::InputDialog.new(
                   parent_shell,
                   title, message, :initial_text => initial_value) do |text|
          block ? block[text] : nil
        end
        code = dialog.open
        button = (code == 0 ? :ok : :cancel)
        {:button => button, :value => dialog.value}
      end

      def password_input(title, message)
        dialog = Dialogs::InputDialog.new(parent_shell, title, message, :password => true)
        code = dialog.open
        button = (code == 0 ? :ok : :cancel)
        {:button => button, :value => dialog.value}
      end

      def tool_tip(message, location)
        tool_tip = Swt::Widgets::ToolTip.new(parent_shell, Swt::SWT::ICON_INFORMATION)
        tool_tip.set_message(message)
        tool_tip.set_location(*get_coordinates(location))
        tool_tip.set_visible(true)
      end

      def popup_menu(menu, location)
        window = Redcar.app.focussed_window
        menu   = ApplicationSWT::Menu.new(window.controller, menu, nil, Swt::SWT::POP_UP)
        menu.move(*get_coordinates(location))
        menu.show
      end

      def popup_text(title, message, location,dimensions=nil)
        if dimensions
          box = ApplicationSWT::ModelessDialog.new(title,message,dimensions[0],dimensions[1])
        else
          box = ApplicationSWT::ModelessDialog.new(title,message)
        end
        box.open(parent_shell,*get_coordinates(location))
      end

      def popup_html(text,location,dimensions=nil)
        if dimensions
          box = ApplicationSWT::ModelessHtmlDialog.new(text,dimensions[0],dimensions[1])
        else
          box = ApplicationSWT::ModelessHtmlDialog.new(text)
        end
        box.open(parent_shell,*get_coordinates(location))
      end

      private

      def get_coordinates(location)
        edit_view = EditView.focussed_tab_edit_view
        if (location == :cursor or location.to_s =~ /^(\d+)$/) and not edit_view
          location = :pointer
        end
        case location
        when :cursor
          x, y = Swt::GraphicsUtils.pixel_location_at_offset(edit_view.cursor_offset)
        when :below_cursor
          x, y = Swt::GraphicsUtils.below_pixel_location_at_offset(edit_view.cursor_offset)
        when :pointer
          location = ApplicationSWT.display.get_cursor_location
          x, y = location.x, location.y
        else
          if location.to_s =~ /^(\d+)$/
            x, y = Swt::GraphicsUtils.pixel_location_at_offset($1.to_i)
          end
        end
        [x, y]
      end

      def file_dialog(type, options)
        dialog = Swt::Widgets::FileDialog.new(parent_shell, type)
        dialog.setText("Save File")
        dialog.setOverwrite(true)
        if options[:filter_path]
          dialog.setText("Save File As") if type == Swt::SWT::SAVE
          dialog.setText("Open File") if type == Swt::SWT::OPEN
          dialog.set_filter_path(options[:filter_path])
        end
        Redcar.app.protect_application_focus do
          dialog.open
        end
      end

      def directory_dialog(options)
        dialog = Swt::Widgets::DirectoryDialog.new(parent_shell)
        dialog.setText("Open Directory")
        if options[:filter_path]
          dialog.set_filter_path(options[:filter_path])
        end
        Redcar.app.protect_application_focus do
          dialog.open
        end
      end

      def parent_shell
        if focussed_window = Redcar.app.focussed_window
          focussed_window.controller.shell
        else
          Redcar.app.controller.fake_shell
        end
      end
    end
  end
end