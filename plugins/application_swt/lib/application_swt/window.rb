
module Redcar
  module ApplicationSWT
    class Window
      def initialize(window)
        @window = window
        @shell = Swt::Widgets::Shell.new(ApplicationSWT.display)
        @shell.open
        helloText = Swt::Widgets::Text.new(@shell, Swt::SWT::CENTER)
        helloText.setText("Hello SWT!")
        helloText.pack()
        @shell.pack()
        @shell.text = window.title
      end
      
      def close
        @shell.close
      end
    end
  end
end
