
module Redcar
  class ReplSWT
    class KeyListener
      def initialize(controller)
        @controller = controller
      end

      def key_pressed(e)
      end

      def key_released(e)
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
            @controller.commit_changes
          end
        when Swt::SWT::DEL
          e.doit = @controller.delete_possible?
        when Swt::SWT::BS
          e.doit = @controller.backspace_possible?
        else
          @controller.check_cursor_location
          e.doit = true
        end
      end
    end
  end
end