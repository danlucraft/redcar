module Redcar
  # A class that holds a cursor navigation history. The maximum length
  # defaults to 100.
  class NavigationHistory < Array
    def initialize()
      @max_history_size = 100
      @current = 0
    end
    
    def save(doc, move_current = true)
      # Invoking this method means new future is about to be created, so remove old one.
      self.slice!(@current...self.size)
      
      while self.size >= @max_history_size
        self.delete_at(0)
        @current -= 1
      end
      
      self << {:path => doc.path, :cursor_offset => doc.cursor_offset}
      @current += 1 if move_current
    end
    
    def can_backward?
      return @current > 0
    end

    def backward
      change_current_and_restore(-1) if can_backward?
    end
    
    def can_forward?
      return @current < self.size - 1
    end

    def forward
      change_current_and_restore(1) if can_forward?
    end
    
    private
    
    def change_current_and_restore(history_size)
      current_doc = Redcar.app.focussed_window.focussed_notebook_tab_document
      if current_doc
        history = {:path => current_doc.path, :cursor_offset => current_doc.cursor_offset}
        if @current < self.size
          self[@current] = history
        else
          self << history
          @current = self.size - 1
        end
      end
      
      @current += history_size
      Project::Manager.open_file(self[@current][:path])
      new_doc = Redcar.app.focussed_window.focussed_notebook_tab_document
      new_doc.cursor_offset = self[@current][:cursor_offset]
      new_doc.ensure_cursor_visible
    end
  end
end