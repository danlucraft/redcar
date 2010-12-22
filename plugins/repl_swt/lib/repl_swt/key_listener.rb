
module Redcar
  class ReplSWT
    class KeyListener
      def initialize(controller)
        @controller = controller
      end

      def key_pressed(e)
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