
require "edit_view/document"
require "edit_view/mirror"
require "edit_view/edit_tab"

module Redcar
  class EditView
    include Redcar::Model
    include Redcar::Observable
    
    attr_reader :document, :tab
    
    def initialize(tab)
      @tab = tab
      create_document
    end
    
    def create_document
      @document = Redcar::Document.new(self)
    end
  end
end
