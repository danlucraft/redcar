
module Redcar
  class EditTab < Tab
    attr_reader :view

    def initialize(pane)
      @view = Redcar::EditView.new
      super pane, @view, :scrolled? => true
    end
    
    def document
      @view.buffer
    end
    
    def on_focus
      @view.grab_focus
    end
  end
end
