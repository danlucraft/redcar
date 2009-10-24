
module Redcar
  class EditTab < Tab
    
    def edit_view
      @edit_view ||= Redcar::EditView.new(self)
    end
  end
end