
require 'java'

module Redcar
  class REPL
    class ReplTab < Redcar::EditTab

      DEFAULT_ICON = :application_terminal

      def initialize(*args, &block)
        super(*args,&block)
      end

      def icon
        DEFAULT_ICON
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
        p length
        p text
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

      class KeyListener
        def initialize(controller)
          @controller = controller
        end

        def key_pressed(e)
          e.doit = false
        end

        def verify_key(e)
          e.doit = false
          case e.keyCode
          when Swt::SWT::ARROW_UP
            command = @controller.edit_view.document.mirror.previous_command
            @controller.set_command(command) if command
          when Swt::SWT::ARROW_DOWN
            command = @controller.edit_view.document.mirror.next_command
            @controller.set_command(command) if command
          when Swt::SWT::CR
            if e.stateMask == Swt::SWT::SHIFT
              e.doit = true
            else
              Redcar::REPL::CommitREPL.new.run
            end
          when Swt::SWT::BS, Swt::SWT::DEL
            # FIXME: find a way to disable these
          else
            if e.stateMask == Swt::SWT::CTRL
              # TODO: kill running process
            else
              @controller.check_cursor_location
              e.doit = true
            end
          end
        end

        def key_released(e)
        end
      end
    end
  end
end