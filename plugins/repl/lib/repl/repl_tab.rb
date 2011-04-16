
module Redcar
  class REPL
    class Tab < Redcar::EditTab

      DEFAULT_ICON = :application_terminal

      def initialize(*args, &block)
        super(*args,&block)
      end

      def icon
        DEFAULT_ICON
      end

      def close
        history = REPL.storage['command_history']
        history[repl_mirror.title] = repl_mirror.command_history
        REPL.storage['command_history'] = history
        notify_listeners(:close)
      end

      def repl_mirror
        edit_view.document.mirror
      end

      def repl_mirror=(mirror)
        edit_view.document.mirror = mirror
        edit_view.cursor_offset = edit_view.document.length
        edit_view.grammar = mirror.grammar_name
        indenters = edit_view.document.controllers(Redcar::AutoIndenter::DocumentController)
        indenters.first.increase_ignore
        update_cursor_size
        attach_listeners
      end

      def attach_listeners
        control = edit_view.controller.mate_text.get_control
        control.add_verify_key_listener(Redcar::ReplSWT::KeyListener.new(self))
        control.remove_key_listener(edit_view.controller.key_listener)
        control.remove_verify_key_listener(edit_view.controller.verify_key_listener)
        repl_mirror.add_listener(:change) do
          edit_view.cursor_offset = edit_view.document.length
          edit_view.scroll_to_line(edit_view.document.line_count)
        end
        edit_view.add_listener(:font_changed) do
          update_cursor_size
        end
      end

      def current_command
        offset     = repl_mirror.current_offset.to_i
        end_offset = edit_view.document.length
        length     = end_offset.to_i - offset.to_i
        edit_view.document.get_range(offset,length) if length > 0
      end

      def cached_command
        @cached_command
      end

      def set_command(text)
        offset = repl_mirror.current_offset.to_i
        length = 0
        length = current_command.split(//).length if current_command
        if length > 0
          edit_view.document.replace(offset,length,text.to_s)
        else
          edit_view.document.cursor_offset = offset
          edit_view.document.insert_at_cursor(text.to_s)
          edit_view.document.cursor_offset = edit_view.document.length
        end
      end

      def go_to_previous_command
        if repl_mirror.command_index == repl_mirror.command_history.size
          @cached_command = current_command
        end
        command = repl_mirror.previous_command
        set_command(command) if command
      end

      def go_to_next_command
        command = repl_mirror.next_command || cached_command
        command = "" if current_command and !command
        set_command(command) if command
      end

      def go_to_home?
        cursor_line = edit_view.document.cursor_line
        prompt_line = edit_view.document.line_at_offset(repl_mirror.current_offset.to_i)
        if cursor_line == prompt_line
          edit_view.document.cursor_offset = repl_mirror.current_offset.to_i
          false
        elsif cursor_line > prompt_line
          edit_view.document.cursor_offset = edit_view.document.offset_at_line(cursor_line)
          false
        else
          true
        end
      end

      def commit_changes
        @cached_command = nil
        edit_view.document.save!
      end

      # Check (and move, if necessary) the cursor position before inserting text
      def check_cursor_location
        offset         = repl_mirror.current_offset
        current_offset = edit_view.document.cursor_offset
        end_offset     = edit_view.document.selection_offset
        if end_offset and end_offset < current_offset
          current_offset = end_offset
          end_offset     = edit_view.document.cursor_offset
        end
        unless current_offset.to_i >= offset
          if edit_view.document.selection? and end_offset > offset
            edit_view.document.set_selection_range(offset,end_offset)
          else
            edit_view.document.cursor_offset = edit_view.document.length
          end
        end
      end

      def backspace_possible?
        check_cursor_location
        length = 0
        length = current_command.split(//).length if current_command
        length > 0
      end

      def delete_possible?
        check_cursor_location
        offset = edit_view.document.cursor_offset
        edit_view.document.length - offset > 0
      end

      private

      def update_cursor_size
        if widget = edit_view.controller.mate_text.get_text_widget
          caret = Swt::Widgets::Caret.new(widget, Swt::SWT::NONE)
          caret.set_image(nil)
          widget.set_caret(caret)
          height = widget.get_line_height
          width  = edit_view.controller.char_width
          caret.set_size(width,height)
          caret.set_visible(true)
        end
      end
    end
  end
end