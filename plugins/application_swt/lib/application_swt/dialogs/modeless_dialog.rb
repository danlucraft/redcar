
module Redcar
  class ApplicationSWT
    class ModelessDialog

      DEFAULT_WIDTH = 300
      DEFAULT_HEIGHT_IN_ROWS = 4

      def initialize(title,message,width=DEFAULT_WIDTH,height=DEFAULT_HEIGHT_IN_ROWS)
        @title   = title
        @message = message
        @width   = width
        @height  = height
      end

      def close
        @text.remove_key_listener(@key_listener)
        @text.remove_focus_listener(@focus_listener)
        @shell.dispose
      end

      def open(parent,*location)
        createDialogArea(parent)
        @shell.set_location(*location)
        @shell.open
      end

      def inspect
        "#<Redcar::ModelessDialog width=#{@width}, height=#{@height}, location=#{@shell.get_location}>"
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
          elsif e.stateMask == Swt::SWT::ALT
          else
            case e.keyCode
            when Swt::SWT::ESC
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

      private

      def createDialogArea(parent)
        display = ApplicationSWT.display
        shell  = Swt::Widgets::Shell.new(parent, Swt::SWT::MODELESS)
        layout = Swt::Layout::GridLayout.new
        layout.marginHeight    = 0
        layout.marginWidth     = 0
        layout.verticalSpacing = 0
        shell.setLayout(layout)

        text = Swt::Custom::StyledText.new(shell, Swt::SWT::WRAP|Swt::SWT::V_SCROLL)
        text.setLayoutData(Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH))
        text.set_editable false
        new_line = "\n"
        new_line = "\r\n" if Redcar.platform == :windows
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
        shell.set_size(@width,convert_to_pixels(@height))
      end

      def convert_to_pixels(rows)
        @text.get_line_height * rows
      end
    end
  end
end