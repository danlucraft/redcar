
require 'html_view/html_tab'

module Redcar
  class HtmlView
    class TestHtmlCommand < Redcar::Command
      class MyFirstJavaFunc < Swt::Browser::BrowserFunction
        def function(*args)
          p [MyFirstJavaFunc, args]
        end
      end
      
      def execute
        tab = win.new_tab(HtmlTab)
        p tab
        tab.title = "HTML 1"
        MyFirstJavaFunc.new(tab.controller.browser, "myFirstJavaFunc")
        tab.controller.browser.set_text(f=<<-HTML)
<h1>It works!</h1><br />

Thanks

<script language="javascript">
  myFirstJavaFunc("hello from javascript");
</script>
HTML
        tab.focus
      end
    end

    def initialize(html_tab)
      @html_tab = html_tab
    end
    
  end
end