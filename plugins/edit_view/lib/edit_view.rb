
require "edit_view/command"
require "edit_view/document"
require "edit_view/mirror"
require "edit_view/edit_tab"

module Redcar
  class EditView
    include Redcar::Model
    include Redcar::Observable
    
    def self.load
    end
    
    attr_reader :document
    
    def initialize(tab)
      @tab = tab
      create_document
    end
    
    def create_document
      @document = Redcar::Document.new(self)
    end
    
    def title=(title)
      @tab.title = title
    end
    
    def cursor_offset=(offset)
      controller.cursor_offset = offset
    end
    
    def cursor_offset
      controller.cursor_offset
    end
  end
end
