module Redcar
  class DocumentCommand < Command
    sensitize :edit_view_focussed
    
    private
    
    def doc
      EditView.current.document
    end
  end
end