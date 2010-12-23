
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
        mirror = edit_view.document.mirror
        history = REPL.storage['command_history']
        history[mirror.title] = mirror.command_history
        REPL.storage['command_history'] = history
        notify_listeners(:close)
      end

      def repl_mirror=(mirror)
        edit_view.document.mirror = mirror
        edit_view.cursor_offset = edit_view.document.length
        edit_view.grammar = mirror.grammar_name
        attach_listeners
      end

      def attach_listeners
        control = edit_view.controller.mate_text.get_control
        control.add_verify_key_listener(Redcar::ReplSWT::KeyListener.new(self))
        control.remove_key_listener(edit_view.controller.key_listener)
        control.remove_verify_key_listener(edit_view.controller.verify_key_listener)
        edit_view.document.mirror.add_listener(:change) do
          edit_view.cursor_offset = edit_view.document.length
          edit_view.scroll_to_line(edit_view.document.line_count)
        end
      end

      def current_command
        command    = ""
        offset     = edit_view.document.mirror.current_offset.to_i
        end_offset = edit_view.document.length
        length     = end_offset.to_i - offset.to_i
        if length > 0
          command = edit_view.document.get_range(offset,length)
        end
        command
      end

      def set_command(text)
        offset = edit_view.document.mirror.current_offset.to_i
        length = current_command.split(//).length
        if length > 0
          edit_view.document.replace(offset,length,text.to_s)
        else
          edit_view.document.cursor_offset = offset
          edit_view.document.insert_at_cursor(text.to_s)
          edit_view.document.cursor_offset = edit_view.document.length
        end
      end

      def commit_changes
        edit_view.document.save!
      end

      def check_cursor_location
        offset = edit_view.document.mirror.current_offset
        current_offset = edit_view.document.cursor_offset
        unless current_offset.to_i >= offset
          edit_view.document.cursor_offset = edit_view.document.length
        end
      end

      def backspace_possible?
        check_cursor_location
        length = current_command.split(//).length
        length > 0
      end

      def delete_possible?
        check_cursor_location
        offset = edit_view.document.cursor_offset
        edit_view.document.length - offset > 0
      end
    end
  end
end