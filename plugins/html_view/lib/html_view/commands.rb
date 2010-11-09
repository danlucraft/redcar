require 'java'

module Redcar
  class HtmlView

    # Open a HtmlTab for displaying web content
    class DisplayWebContent < Redcar::Command
      def initialize(name,url,display_bar=true,tab_class=HtmlTab)
        @name        = name
        @url         = url
        @display_bar = display_bar
        @tab         = tab_class
      end

      def execute
        use_external = HtmlView.storage['use_external_browser_for_urls']
        if use_external and OpenDefaultBrowserCommand.supported?
          OpenDefaultBrowserCommand.new(@url).run
        else
          win = Redcar.app.focussed_window
          controller = DefaultController.new(@name,@url)
          tab = win.new_tab(@tab)
          tab.html_view.controller = controller
          tab.icon = HtmlTab.web_content_icon if tab.is_a?(HtmlTab)
          tab.focus
          if @display_bar
            HtmlView::OpenBrowserBar.new.run
          end
        end
      end
    end

    class FileWebPreview < Redcar::EditTabCommand
      def execute
        mirror  = doc.mirror
        if mirror and path = mirror.path and File.exists?(path)
          name = "Preview: " +File.basename(path)
        else
          name    = "Preview"
          preview = java.io.File.createTempFile("preview","html")
          preview.deleteOnExit
          path    = preview.getAbsolutePath
          File.open(path,'w') {|f| f.puts(doc.get_all_text)}
        end
        url = File.expand_path(path)
        DisplayWebContent.new(name,url).run
      end
    end

    class OpenBrowserBar < Redcar::Command
      def execute
        window = Redcar.app.focussed_window
        speedbar = Redcar::HtmlView::BrowserBar.new
        window.open_speedbar(speedbar)
      end
    end
  end
end