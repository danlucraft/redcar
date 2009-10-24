
module Redcar
  class Document
    include Redcar::Model
    include Redcar::Observable
    
    def initialize(edit_view)
      @edit_view = edit_view
    end
    
    def to_s
      controller.to_s
    end
    
    def text=(text)
      controller.text = text
    end
  end
end