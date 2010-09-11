module Redcar
  class DocumentCommand < Command
    sensitize :edit_view_focussed
    
    def _finished
      EditView.focussed_edit_view.history.record(self)
    end
    
    private
    
    def doc
      EditView.focussed_edit_view.document
    end
  end
end