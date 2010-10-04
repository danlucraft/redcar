
module Redcar
  class WebBookmarks
    class BrowserBar < Redcar::Speedbar

      def html_tab
        tab = Redcar.app.focussed_window.focussed_notebook_tab
        tab if tab.is_a?(Redcar::HtmlTab)
      end

      button :back, "Back", "Ctrl+Left" do
        html_tab.controller.browser.back if html_tab
      end

      button :forward, "Forward", "Ctrl+Right" do
        html_tab.controller.browser.forward if html_tab
      end

      button :stop, "Stop", nil do
        html_tab.controller.browser.stop if html_tab
      end

      button :refresh, "Refresh", "F5" do
        html_tab.controller.browser.refresh if html_tab
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