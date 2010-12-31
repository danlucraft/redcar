
module Redcar
  class ApplicationSWT
    class ModelessHtmlDialog

      DEFAULT_WIDTH = 300
      DEFAULT_HEIGHT = 100

      def initialize(text,width=DEFAULT_WIDTH,height=DEFAULT_HEIGHT)
        @text   = text
        @width  = width
        @height = height
      end

      def close
        # @browser.remove_focus_listener(@focus_listener)
        @browser.remove_key_listener(@key_listener)
        @browser.dispose
        @shell.dispose
      end

      def open(parent,*location)
        createDialogArea(parent)
        @shell.set_location(*location)
        @shell.open
        # getting browser focus events does not work - SWT #84532
        # @focus_listener = ModelessDialog::FocusListener.new(self)
        # @browser.add_focus_listener(@focus_listener)
        # @browser.set_focus
      end

      private

      def createDialogArea(parent)
        display = ApplicationSWT.display
        @shell  = Swt::Widgets::Shell.new(parent, Swt::SWT::MODELESS)
        layout = Swt::Layout::GridLayout.new
        layout.marginHeight    = 0
        layout.marginWidth     = 0
        layout.verticalSpacing = 0
        @shell.set_layout(layout)
        @browser = Swt::Browser.new(@shell, Swt::SWT::MOZILLA)
        @browser.set_layout_data(Swt::Layout::GridData.new(Swt::Layout::GridData::FILL_BOTH))
        @shell.set_size(@width, @height)

        @key_listener   = ModelessDialog::KeyListener.new(self)
        @browser.add_key_listener(@key_listener)
        @browser.set_text(@text)
        ApplicationSWT.register_shell(@shell)
      end
    end
  end
end