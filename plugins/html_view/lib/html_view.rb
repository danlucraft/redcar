
require 'html_view/html_tab'
require 'html_controller'
require 'json'

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
      attach_controller_listeners
    end
    
    def attach_controller_listeners
      @controller.add_listener(:reload_index) { controller_action("index") }

      @controller.add_listener(:execute_script) do |script|
        result = nil
        begin
          Redcar.update_gui do
            begin
              browser = @html_tab.controller.browser
              unless browser.is_disposed
                result = browser.evaluate(script)
              end
            rescue => e
              puts e.message
              puts e.backtrace
            end
          end
        rescue => e
          puts e.message
          puts e.backtrace
        end
        result
      end
    end
    
    def controller_action(action_name, params=nil)
      text = nil
      begin
        action_method_arity = controller.method(action_name).arity
        text = if action_method_arity == 0
                 controller.send(action_name)
               elsif action_method_arity == 1
                 controller.send(action_name, params)
               end
      rescue => e
        text = <<-HTML
          Sorry, there was an error.<br />
          <pre><code>
            #{e.message}
            #{e.backtrace}
          </code></pre>
        HTML
      end
      if text
        unless @html_tab.controller.browser.disposed
          @html_tab.controller.browser.set_text(text.to_s + setup_javascript_listeners)
        end
      end
    end
    
    def contents=(source)
      @html_tab.controller.browser.set_text(source)
    end
    
    private
    
    class RubyFunc < Swt::Browser::BrowserFunction
      def function(args)
        begin
          if result = controller.send(*args.to_a)
            return JSON(result)
          else
            return "{}"
          end
        rescue JSON::GeneratorError => e
          nil
        rescue Object => e
          puts "caught in controller"
          puts e.message
          puts e.backtrace
        end
      end
      
      attr_accessor :controller
    end

    # TODO: remove this method once we have a default layout that
    #       has <%= javascript_controller_actions %>
    def setup_javascript_listeners
      controller.javascript_controller_actions
    end
  end
end
