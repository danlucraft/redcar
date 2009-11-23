module Redcar
  class EditTab < Tab
    include Redcar::Observable
    
    attr_reader :edit_view
    
    def initialize(*args)
      super
      create_edit_view
    end
    
    def create_edit_view
      @edit_view = Redcar::EditView.new(self)
      @edit_view.add_listener(:focussed, &method(:edit_view_focussed))
    end
    
    def edit_view_focussed
      notify_listeners(:focussed)
    end
    
    def title
      edit_view.document ? (edit_view.document.title || super) : super
    end
    
    def serialize
      { :edit_view     => edit_view.serialize }
    end
    
    def deserialize(data)
      edit_view.deserialize(data[:edit_view])
    end
  end
end
