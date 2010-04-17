
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
                                      (Redcar.root + "/vendor/xulrunner").gsub("/", "\\"))
          @browser = Swt::Browser.new(notebook.tab_folder, Swt::SWT::MOZILLA)
        else
          @browser = Swt::Browser.new(notebook.tab_folder, Swt::SWT::NONE)
        end
        @widget = @browser
        @item.control = @widget
        add_listeners
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
      
      class LocationListener
        def initialize(html_tab)
          @html_tab = html_tab
        end
        
        def changing(event)
          if event.location =~ %r{file:///controller/([^/]*)(/(.*))?}
            event.doit = false
            @html_tab.controller_action($1, $2)
          end
        end

        def changed(*_); end
      end
      
      def add_listeners
        @browser.add_location_listener(LocationListener.new(@model))
      end
    end
  end
end
