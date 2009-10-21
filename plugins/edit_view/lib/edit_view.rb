
require "edit_view/mirror"
require "edit_view/edit_tab"

module Redcar
  class EditView
    include Redcar::Model
    
    def initialize(controller)
      @controller = controller
    end
    
    def document
      @document ||= controller.document
    end
  end
end
