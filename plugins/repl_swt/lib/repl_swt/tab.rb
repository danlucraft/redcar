
module Redcar
  class ReplSWT
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
        control = edit_view.controller.mate_text.get_control
        control.add_verify_key_listener(KeyListener.new(self))
        mirror.add_listener(:change) do
          edit_view.cursor_offset = edit_view.document.length
          edit_view.scroll_to_line(edit_view.document.line_count)
        end
      end

      def set_command(text)
        offset     = edit_view.document.mirror.current_offset.to_i
        end_offset = edit_view.document.length
        length     = end_offset.to_i - offset.to_i
        if length > 0
          edit_view.document.replace(offset,length,text.to_s)
        else
          edit_view.document.cursor_offset = offset
          edit_view.document.insert_at_cursor(text.to_s)
          edit_view.document.cursor_offset = edit_view.document.length
        end
      end

      def check_cursor_location
        offset = edit_view.document.mirror.current_offset
        current_offset = edit_view.document.cursor_offset
        unless current_offset.to_i >= offset
          edit_view.document.cursor_offset = edit_view.document.length
        end
      end
    end
  end
end