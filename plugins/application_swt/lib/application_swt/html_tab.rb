
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
                                      HtmlTab.windows_xulrunner_path.gsub("/", "\\"))
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
        @browser.remove_location_listener(@location_listener)
        @browser.dispose
        @location_listener = nil
        super
      end
      
      def go_to_location(url)
        @browser.set_url(url)
      end
      
      class LocationListener
        def initialize(html_tab)
          @html_tab = html_tab
        end
        
        def changing(event)
          uri = URI.parse(event.location)
          if uri.path =~ %r{/controller/([^/]*)}
            event.doit = false
            params = uri.query ? CGI.parse(uri.query) : nil
            @html_tab.controller_action($1, params)
          end
        end

        def changed(*_); end
      end
      
      def add_listeners
        @location_listener = LocationListener.new(@model)
        @browser.add_location_listener(@location_listener)
      end
      
      def self.windows_xulrunner_path
        begin
          require 'redcar-xulrunner-win'
        rescue LoadError => e
          raise "Missing xulrunner browser widget, install gem redcar-xulrunner-win."
        end
        Redcar::XulrunnerWin.ensure_unpacked
        Redcar::XulrunnerWin.path
      end
    end
  end
end
