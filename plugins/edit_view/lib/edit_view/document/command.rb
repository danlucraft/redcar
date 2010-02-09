module Redcar
  class DocumentCommand < Command
    sensitize :edit_view_focussed
    
    private
    
    def doc
      EditView.focussed_edit_view.document
    end
  end
end