module Redcar
  class REPL
    class ReplTab < Redcar::EditTab
      
      DEFAULT_ICON = :application_terminal
      
      def initialize(*args, &block)
        super(*args,&block)
      end
      
      def icon
        DEFAULT_ICON
      end
      
      def repl_mirror=(mirror)
        edit_view.document.mirror = mirror
        edit_view.cursor_offset = edit_view.document.length
        edit_view.grammar = mirror.grammar_name
        mirror.add_listener(:change) do
          edit_view.cursor_offset = edit_view.document.length
          edit_view.scroll_to_line(edit_view.document.line_count)
        end
      end
    end
  end
end