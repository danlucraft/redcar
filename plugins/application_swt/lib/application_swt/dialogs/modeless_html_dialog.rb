
module Redcar
  class ApplicationSWT
    class ModelessHtmlDialog
      attr_reader :width, :height

      DEFAULT_WIDTH  = 300
      DEFAULT_HEIGHT = 100

      def initialize(text,width=DEFAULT_WIDTH,height=DEFAULT_HEIGHT)
        @text   = text
        @width  = width
        @height = height
      end

      # Close and dispose of the dialog
      def close
        # @browser.remove_focus_listener(@focus_listener)
        @browser.remove_key_listener(@key_listener)
        @browser.dispose
        @shell.dispose
      end

      # Opens the dialog.
      #
      # @returns the dialog
      def open(parent,*location)
        createDialogArea(parent)
        @shell.set_location(*location)
        @shell.open
        # getting browser focus events does not work - SWT #84532
        # @focus_listener = ModelessDialog::FocusListener.new(self)
        # @browser.add_focus_listener(@focus_listener)
        # @browser.set_focus
        self
      end

      # Set the text to be rendered by the dialog
      def text=(text)
        @browser.set_text text
      end

      # Set the dialog to render a given URL
      def url=(url)
        @browser.set_url url
      end

      # Change the dialog size
      def set_size(width,height)
        @width  = width
        @height = height
        @shell.set_size(@width, @height)
      end

      # Refresh the rendered content
      def refresh
        @browser.refresh
      end

      def inspect
        "#<Redcar::ModelessHtmlDialog width=#{@width}, height=#{@height}, location=#{@shell.get_location}>"
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