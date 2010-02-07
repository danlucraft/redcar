module Redcar
  class DocumentCommand < Command
    sensitize :edit_view_focussed
    
    private
    
    def doc
      tab.edit_view.document
    end
  end
end