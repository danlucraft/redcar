module Redcar
  class DocumentCommand < Command
    sensitize :edit_view_focussed
    
    def _finished
      EditView.focussed_edit_view.history.record(self)
    end
    
    private
    
    def edit_view
      env[:edit_view] || EditView.focussed_edit_view
    end
    
    def doc
      edit_view.document
    end
  end
end