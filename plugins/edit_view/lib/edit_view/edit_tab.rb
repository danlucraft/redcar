module Redcar
  class EditTab < Tab
    
    attr_reader :edit_view

    def initialize(*args)
      super
      create_edit_view
    end

    def update_for_file_changes
      doc = @edit_view.document
      if doc and doc.path
        if doc.mirror.adapter.is_a?(Redcar::Project::Adapters::Remote)
          new_icon = DEFAULT_ICON
        elsif File.exists?(doc.path)
          if File.writable?(doc.path)
            new_icon = DEFAULT_ICON
          else
            new_icon = NO_WRITE_ICON
          end
        else
          new_icon = MISSING_ICON
        end
      end
      if new_icon and new_icon != @icon
        @icon = new_icon 
        notify_listeners(:changed_icon, @icon)
      end
    end

    def create_edit_view
      @edit_view = Redcar::EditView.new
      @edit_view.add_listener(:focussed, &method(:edit_view_focussed))
      @edit_view.document.add_listener(:changed) { notify_listeners(:changed, self) }
      @edit_view.document.add_listener(:selection_range_changed) { notify_listeners(:selection_changed) }
      @edit_view.add_listener(:title_changed) { |newt| self.title = newt }
      update_for_file_changes
    end

    def edit_view_focussed
      notify_listeners(:focus)
    end
  end
end
