

module Redcar
  class HtmlTab < Tab
    attr_reader :html_view
  
    def initialize(*args)
      super
      create_html_view
    end
    
    def close
      html_view.controller.close if html_view.controller
      super
    end
    
    def create_html_view
      @html_view = HtmlView.new(self)
    end
    
    def controller_action(action, params)
      notify_listeners(:controller_action, action, params)
    end
    
    def go_to_location(url)
      controller.go_to_location(url)
    end
  end
end
