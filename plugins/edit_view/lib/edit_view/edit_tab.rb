
module Redcar
  class EditTab < Tab
    attr_reader :edit_view
    
    def initialize(*args)
      super
      create_edit_view
    end
    
    def create_edit_view
      @edit_view = Redcar::EditView.new(self)
    end
    
    def title=(title)
      notify_listeners(:changed_title, title)
    end
  end
end
