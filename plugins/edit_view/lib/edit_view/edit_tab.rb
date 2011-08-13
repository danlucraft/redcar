module Redcar
  class EditTab < Tab

    attr_reader :edit_view

    def initialize(*args)
      super
      create_edit_view
    end

    def icon
      i = DEFAULT_ICON
      doc = @edit_view.document
      if doc and doc.path
        unless doc.mirror.adapter.is_a?(Redcar::Project::Adapters::Remote)
          if File.exists?(doc.path)
            if File.writable?(doc.path)
              key = File.basename(doc.path).split('.').last.split(//).first.downcase
              if key =~ /[a-z]/
                if key == 'a'
                  i = :document_attribute
                else
                  i = :"document_attribute_#{key}"
                end
              else
                i = DEFAULT_ICON
              end
            else
              i = NO_WRITE_ICON
            end
          else
            i = MISSING_ICON
          end
        end
      end
      i
    end

    def update_for_file_changes
      new_icon = icon
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
    end

    def edit_view_focussed
      notify_listeners(:focus)
    end
  end
end
