
module Redcar
  class Snippets
    class DocumentController
      include Redcar::Document::Controller
      include Redcar::Document::Controller::ModificationCallbacks
      include Redcar::Document::Controller::CursorCallbacks

      attr_reader :current_snippet

      def before_modify(start_offset, end_offset, text)
      end
      
      def after_modify
      end
      
      def cursor_moved(new_offset)
      end
      
      def start_snippet!(snippet)
        @current_snippet = snippet
        document.insert_at_cursor(snippet.content)
        document.cursor_offset += snippet.content.length
      end
      
      def in_snippet?
        !!current_snippet
      end
    end
  end
end