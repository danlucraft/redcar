
module Redcar
  class EditTab < Tab
    
    def document
      @document ||= controller.document
    end
  end
end