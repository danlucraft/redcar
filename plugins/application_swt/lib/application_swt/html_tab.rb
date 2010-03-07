
module Redcar
  class ApplicationSWT
    class HtmlTab < Tab
      attr_reader :browser
      
      def initialize(model, notebook)
        super
        @model.add_listener(:changed_title) { |title| @item.text = title }
      end
      
      def create_tab_widget
        Swt::Graphics::Device.DEBUG = true
        if Redcar.platform == :windows
          java.lang.System.setProperty('org.eclipse.swt.browser.XULRunnerPath',
                                       File.join(Redcar.root, %w(vendor xulrunner)))
          @browser = Swt::Browser.new(notebook.tab_folder, Swt::SWT::MOZILLA)
        else
          @browser = Swt::Browser.new(notebook.tab_folder, Swt::SWT::NONE)
        end
        @widget = @browser
        @item.control = @widget
      end
      
      # Focuses the Browser tab within the CTabFolder, and gives the keyboard
      # focus to the EditViewSWT.
      def focus
        super
        browser.set_focus
      end
      
      # Close the HtmlTab, disposing of any resources along the way.
      def close
        @browser.dispose
        super
      end
    end
  end
end
