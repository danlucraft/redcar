module Redcar
  class REPL
    module ReplMirror
      include Redcar::Document::Mirror
  
      # Execute a new statement. Accepts the entire pretty formatted history,
      # within which it looks for the last statement and executes it.
      #
      # @param [String] a string with at least one prompt and statement in it
      def commit(contents)
        if contents.split("\n").last =~ /#{@prompt}\s+$/
          command = ""
        else
          command = contents.split(@prompt).last.strip
        end
        send_to_repl command
      end

      # REPLs always exist because there is no external resource to represent.
      def exists?
        true
      end

      # REPLs never change except for after commit operations.
      def changed?
        false
      end
      
      private
      
      def update_edit_view
        notify_listeners(:change)
        edit_view = @win.focussed_notebook.focussed_tab.edit_view
        edit_view.cursor_offset = edit_view.document.length
        edit_view.scroll_to_line(edit_view.document.line_count)
      end
      
      # Language-specific method for evaluating statements
      def send_to_repl expr
        raise "not implemented"
      end
      
    end
  end
end