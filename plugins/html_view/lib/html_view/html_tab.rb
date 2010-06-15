

module Redcar
  class HtmlTab < Tab
    attr_reader :html_view
  
    def initialize(*args)
      super
      create_html_view
    end
    
    def create_html_view
      @html_view = HtmlView.new(self)
    end
    
    def controller_action(action, params)
      notify_listeners(:controller_action, action, params)
    end
  end
end