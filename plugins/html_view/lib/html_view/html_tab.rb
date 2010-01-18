

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
  end
end