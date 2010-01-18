
require 'html_view/html_tab'

module Redcar
  class HtmlView
    class TestHtmlCommand < Redcar::Command
      def execute
        tab = win.new_tab(HtmlTab)
        p tab
        tab.title = "HTML 1"
        tab.controller.browser.set_text("<h1>It works!</h1><br />Thanks")
        tab.focus
      end
    end

    def initialize(html_tab)
      @html_tab = html_tab
    end
    
  end
end