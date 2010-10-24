module Redcar
  class EditTab < Tab

    attr_reader :edit_view

    def initialize(*args)
      super
      create_edit_view
    end

    def update_for_file_changes
      old_icon = @icon
      doc = @edit_view.document
      if doc and doc.path
        if File.exists?(doc.path)
          @icon = :file if icon == :exclamation
        else
          if doc.modified?
            @icon = :exclamation
          else
            close
          end
        end
      end
      notify_listeners(:changed_icon, @icon) if old_icon != @icon
    end

    def create_edit_view
      @edit_view = Redcar::EditView.new
      @edit_view.add_listener(:focussed, &method(:edit_view_focussed))
      @edit_view.document.add_listener(:changed) { notify_listeners(:changed, self) }
      @edit_view.document.add_listener(:selection_range_changed) { notify_listeners(:selection_changed) }
      @edit_view.add_listener(:title_changed) { |newt| self.title = newt }
    end

    def edit_view_focussed
      notify_listeners(:focus)
    end
  end
end
