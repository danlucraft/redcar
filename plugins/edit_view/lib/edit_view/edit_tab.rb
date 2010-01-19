module Redcar
  class EditTab < Tab
    
    attr_reader :edit_view
    
    def initialize(*args)
      super
      create_edit_view
    end
    
    def create_edit_view
      @edit_view = Redcar::EditView.new(self)
      @edit_view.add_listener(:focussed, &method(:edit_view_focussed))
      @edit_view.document.add_listener(:changed) { notify_listeners(:changed, self) }
      @edit_view.document.add_listener(:selection_range_changed) { notify_listeners(:selection_changed) }
    end
    
    def edit_view_focussed
      notify_listeners(:focus)
    end

    def serialize
      { :title     => title }
    end
    
    def deserialize(data)
      self.title = data[:title]
    end
  end
end
