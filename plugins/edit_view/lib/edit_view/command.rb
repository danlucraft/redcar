module Redcar
  class EditTabCommand < TabCommand

    sensitize :edit_tab_focussed
    
    private
    
    def doc
      tab.edit_view.document
    end
  end
end