
module Redcar
  # EditTab is the default class of tab that is used for 
  # editing in Redcar. EditTab is a subclass of Tab that contains
  # one instance of EditView.
  class EditTab < Tab
    # an EditView instance.
    attr_reader :view

    # Do not call this directly. Use Window#new_tab or 
    # Pane#new_tab instead:
    # 
    #   win.new_tab(EditTab)
    #   pane.new_tab(EditTab)
    def initialize(pane)
      @view = Redcar::EditView.new
      super pane, @view, :scrolled? => true
    end
    
    # Returns the Redcar::Document for this EditTab.
    def document
      @view.buffer
    end
  end
end
