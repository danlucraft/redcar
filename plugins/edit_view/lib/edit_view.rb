
require "edit_view/document"
require "edit_view/mirror"
require "edit_view/edit_tab"

module Redcar
  class EditView
    include Redcar::Model
    include Redcar::Observable
    
    def initialize(tab)
      @tab = tab
    end
    
    def document
      @document ||= begin 
        doc = EditView::Document.new(self)
        notify_listeners(:new_document, doc)
        doc
      end
    end
  end
end
