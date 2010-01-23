
require 'html_view/html_tab'

module Redcar
  class HtmlView
    attr_reader :controller
  
    def initialize(html_tab)
      @html_tab = html_tab
    end
    
    def controller=(new_controller)
      @controller = new_controller
      @html_tab.title = controller.title
      setup_javascript_listeners
      text = controller.index
      @html_tab.controller.browser.set_text(text)
    end
    
    private
    
    class RubyFunc < Swt::Browser::BrowserFunction
      def function(args)
        func_name = args.to_a.first
        func_args = args.to_a.last.to_a
        controller.send(func_name.to_sym, *func_args)
      end
      
      attr_accessor :controller
    end
        
    def setup_javascript_listeners
      func = RubyFunc.new(@html_tab.controller.browser, "rubyCall")
      func.controller = @controller
      js = []
      js << "Controller = {"
      (controller.methods - Object.new.methods).each do |method_name|
        js << "  #{method_name.gsub(/_(\w)/) { |a| $1.upcase}}: function() {"
        js << "    rubyCall(\"#{method_name}\", arguments);"
        js << "  },"
      end
      js << "}"
      @html_tab.controller.browser.evaluate(js.join("\n"))
    end
  end
end