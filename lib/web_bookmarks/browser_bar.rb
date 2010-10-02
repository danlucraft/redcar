
module Redcar
  class WebBookmarks
    class BrowserBar < Redcar::Speedbar

      def html_tab
        tab = Redcar.app.focussed_window.focussed_notebook_tab
        tab if tab.is_a?(Redcar::HtmlTab)
      end

      button :back, "Back", "Ctrl+Left" do
        @tab = html_tab
        if @tab
          @tab.controller.browser.back
        end
      end

      button :forward, "Forward", "Ctrl+Right" do
        @tab = html_tab
        if @tab
          @tab.controller.browser.forward
        end
      end

      button :stop, "Stop", "Ctrl+S" do
        @tab = html_tab
        if @tab
          @tab.controller.browser.stop
        end
      end

      button :refresh, "Refresh", "Ctrl+R" do
        @tab = html_tab
        if @tab
          @tab.controller.browser.refresh
        end
      end

      label :url_label, "New URL:"
      textbox :new_url

      button :go_to_url, "Go!", "Enter" do
        @tab = html_tab
        if @tab
          unless new_url.value == ""
            @tab.title=new_url.value
            @tab.controller.go_to_location(new_url.value)
          end
        end
      end
    end
  end
end