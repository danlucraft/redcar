module Redcar
  class EditTabCommand < TabCommand

    sensitize :edit_tab_focussed
    
    def doc
      edit_view.document
    end
    
    def edit_view
      tab.edit_view
    end
  end
end