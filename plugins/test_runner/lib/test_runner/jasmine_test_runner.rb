module Redcar
  class JasmineTestRunner
    def initialize(config)
      @jasmine_url = config[:jasmine_url] || "http://localhost:8888"
    end
    
    def run_test(path, current_line)
      if jasmine_tab = Redcar.app.all_tabs.detect {|t| t.title == "Jasmine Test Runner" }
        jasmine_tab.html_view.refresh
      else
        Redcar::HtmlView::DisplayWebContent.new("Jasmine Test Runner", @jasmine_url).execute
      end
    end
  end
end