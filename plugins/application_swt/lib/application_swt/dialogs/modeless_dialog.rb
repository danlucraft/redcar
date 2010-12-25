
module Redcar
  class ApplicationSWT
    class ModelessDialog
      def initialize(title,message,width=300,height=100)
        @title   = title
        @message = message
        @width   = width
        @height  = height
      end

      def createDialogArea(parent)
        display = ApplicationSWT.display
        shell  = Swt::Widgets::Shell.new(parent, Swt::SWT::MODELESS)
        layout = Swt::Layout::GridLayout.new
        layout.marginHeight    = 0
        layout.marginWidth     = 0
        layout.verticalSpacing = 0
        shell.setLayout(layout)
        shell.set_size(@width,@height)

        text = Swt::Custom::StyledText.new(shell, Swt::SWT::WRAP|Swt::SWT::V_SCROLL)
        text.setLayoutData(Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH))
        text.set_editable false
        new_line = "\n\n"
        new_line = "\r\n\r\n" if Redcar.platform == :windows
        text.set_text(@title + new_line + @message)
        style1 = Swt::Custom::StyleRange.new
        style1.start = 0
        style1.length = @title.split(//).length
        style1.fontStyle = Swt::SWT::BOLD
        style1.foreground = display.getSystemColor(Swt::SWT::COLOR_WHITE)
        text.setStyleRange(style1)
        text.set_margins(2,2,2,2)
        text.setBackground(Swt::Graphics::Color.new(display, 230, 240, 255))
        text.setLineBackground(0, 1, Swt::Graphics::Color.new(display, 135, 178, 247))
        @key_listener = KeyListener.new(self)
        @focus_listener = FocusListener.new(self)
        text.add_key_listener(@key_listener)
        text.add_focus_listener(@focus_listener)
        ApplicationSWT.register_shell(shell)
        @text  = text
        @shell = shell
      end

      def close
        @text.remove_key_listener(@key_listener)
        @text.remove_focus_listener(@focus_listener)
        @shell.dispose
      end

      class KeyListener

        def initialize(text)
          @text = text
        end

        def key_pressed(e)
        end

        def key_released(e)
          if e.stateMask == Swt::SWT::CTRL
            case e.keyCode
            when 97
              e.widget.select_all
            when 99
              e.widget.copy
            end
          else
            case e.keyCode
            when Swt::SWT::ARROW_DOWN, Swt::SWT::ARROW_UP
            when Swt::SWT::ARROW_LEFT, Swt::SWT::ARROW_RIGHT
            else
              @text.close
            end
          end
        end
      end

      class FocusListener
        def initialize(text)
          @text = text
        end

        def focus_gained(e)
        end

        def focus_lost(e)
          @text.close
        end
      end
    end
  end
end