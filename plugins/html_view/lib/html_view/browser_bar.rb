
module Redcar
  class HtmlView
    class BrowserBar < Redcar::Speedbar

      def tab_changed(tab)
        unless tab.is_a?(HtmlTab)
          win = Redcar.app.focussed_window
          win.close_speedbar
        end
      end

      def html_tab
        tab = Redcar.app.focussed_window.focussed_notebook_tab
        tab if tab.is_a?(Redcar::HtmlTab)
      end

      button :back, "<", "Ctrl+Left" do
        html_tab.controller.browser.back if html_tab
      end

      button :forward, ">", "Ctrl+Right" do
        html_tab.controller.browser.forward if html_tab
      end

      button :stop, "Stop", nil do
        html_tab.controller.browser.stop if html_tab
      end

      button :refresh, "Refresh", "F5" do
        if tab = html_tab
          url = tab.controller.browser.url.to_s
          Redcar.plugin_manager.objects_implementing(:before_web_refresh).each do |obj|
            obj.before_web_refresh(path)
          end
          tab.controller.browser.refresh
        end
      end

      button :source, "Source", nil do
        if html = html_tab and url = html.controller.browser.url.to_s
          tab  = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
          if url =~ /^file:\/\//
            file_path = url[7,url.length]
            mirror = Redcar::Project::FileMirror.new(file_path)
            tab.edit_view.document.mirror = mirror
          else
            tab.edit_view.document.text = html_tab.controller.browser.text
            tab.title = "Page Source"
          end
          tab.edit_view.grammar = "HTML"
          tab.edit_view.reset_undo
          tab.focus
        end
      end

      button :add, "+", nil do
        if tab = html_tab and
          url = tab.controller.browser.url.to_s
          Redcar::WebBookmarks::AddBookmark.new(url).run
        end
      end

      label :url_label, "New URL:"
      textbox :new_url

      button :go_to_url, "Go!", "Return" do
        unless new_url.value == ""
          url = new_url.value
          if tab = html_tab
            tab.title = url
            tab.controller.go_to_location(HtmlView.tidy_url(url))
            icon = HtmlTab.web_content_icon
            tab.icon = icon unless tab.icon == icon
          else
            Redcar::HtmlView::DisplayWebContent.new(url,url).run
          end
        end
      end
    end
  end
end
