
require 'html_view/html_tab'

module Redcar
  class HtmlView
    def self.default_css_path
      File.expand_path(File.join(Redcar.root, %w(plugins html_view assets redcar.css)))
    end
    
    def self.jquery_path
      File.expand_path(File.join(Redcar.root, %w(plugins html_view assets jquery-1.4.min.js)))
    end
    
    attr_reader :controller
  
    def initialize(html_tab)
      @html_tab = html_tab
      @html_tab.add_listener(:controller_action, &method(:controller_action))
    end
    
    def controller=(new_controller)
      @controller = new_controller
      @html_tab.title = controller.title
      func = RubyFunc.new(@html_tab.controller.browser, "rubyCall")
      func.controller = @controller
      controller_action("index")
    end
    
    def controller_action(action_name, path=nil)
      action_method_arity = controller.method(action_name).arity
      begin
        text = if action_method_arity == 0
                 controller.send(action_name)
               elsif action_method_arity == 1
                 controller.send(action_name, path)
               end
      rescue => e
        text = <<-HTML
          Sorry, there was an error.<br />
          #{e.message}
        HTML
      end
      @html_tab.controller.browser.set_text(text + setup_javascript_listeners)
    end
    
    def contents=(source)
      @html_tab.controller.browser.set_text(source)
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
      js << "Controller = {"
      methods = []
      (controller.methods - Object.new.methods).each do |method_name|
        method = []
        method << "  #{method_name.gsub(/_(\w)/) { |a| $1.upcase}}: function() {"
        method << "    rubyCall(\"#{method_name}\", Array.prototype.slice.call(arguments));"
        method << "  }"
        methods << method.join("\n")
      end
      js << methods.join(",\n")
      js << "};"
      js << "</script>"
      js.join("\n")
    end
  end
end
