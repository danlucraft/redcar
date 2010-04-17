

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
    
    def controller_action(action, path)
      notify_listeners(:controller_action, action, path)
    end
  end
end