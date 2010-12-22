
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
            @controller.commit_changes
          end
        when Swt::SWT::BS, Swt::SWT::DEL
          # FIXME: find a way to disable these
          e.keyCode = Swt::SWT::NONE
          e.character = Swt::SWT::NONE
        when Swt::SWT::TAB
          if e.stateMask == Swt::SWT::SHIFT and
            @controller.respond_to?(:autocomplete_menu)
            @controller.autocomplete_menu(@controller.current_command)
          else
            e.doit = true
          end
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