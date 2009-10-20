
module Redcar
  class EditTab < Tab
    
    def edit_view
      Redcar::EditView.new(controller.edit_view)
    end
  end
end