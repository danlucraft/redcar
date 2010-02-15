
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
      func = RubyFunc.new(@html_tab.controller.browser, "rubyCall")
      func.controller = @controller
      text = controller.index + setup_javascript_listeners
      puts text
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
      js = []
      js << "<script type=\"text/javascript\">"
      js << "this.Controller = {"
      (controller.methods - Object.new.methods).each do |method_name|
        js << "  #{method_name.gsub(/_(\w)/) { |a| $1.upcase}}: function() {"
        js << "    rubyCall(\"#{method_name}\", Array.prototype.slice.call(arguments));"
        js << "  },"
      end
      js << "};"
      js << "</script>"
      js.join("\n")
    end
  end
end
