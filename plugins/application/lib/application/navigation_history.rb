module Redcar
  # A class that holds a cursor navigation history. The maximum length
  # defaults to 100.
  class NavigationHistory < Array
    def initialize
      @max_history_size = 100
      @current = 0
    end
    
    def save(doc)
      return if last && last[:path] == doc.path && last[:cursor_offset] == doc.cursor_offset
      
      # Invoking this method means new future is about to be created, so remove old one.
      self.slice!(@current...self.size)
      
      ensure_size_less_than_max
      self << {:path => doc.path, :cursor_offset => doc.cursor_offset}
      @current += 1
    end
    
    def can_backward?
      return @current > 0
    end

    def backward
      move_current_and_restore(-1) if can_backward?
    end
    
    def can_forward?
      return @current < self.size - 1
    end

    def forward
      move_current_and_restore(1) if can_forward?
    end
    
    private
    
    def ensure_size_less_than_max
      while self.size >= @max_history_size
        self.delete_at(0)
        @current -= 1
      end
    end
    
    def move_current_and_restore(history_size)
      save_current_doc
      @current += history_size
      restore_hisotry
    end
    
    def restore_hisotry
      Project::Manager.open_file(self[@current][:path])
      new_doc = Redcar.app.focussed_window.focussed_notebook_tab_document
      new_doc.cursor_offset = self[@current][:cursor_offset]
      new_doc.ensure_cursor_visible
    end
    
    def save_current_doc
      if win = Redcar.app.focussed_window and cur_doc = win.focussed_notebook_tab_document
        history = {:path => cur_doc.path, :cursor_offset => cur_doc.cursor_offset}
        if @current < self.size
          self[@current] = history
        else
          save(cur_doc)
          @current = self.size - 1
        end
      end
    end
  end
end