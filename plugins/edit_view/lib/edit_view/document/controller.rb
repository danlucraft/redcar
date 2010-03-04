
module Redcar
  class Document
    module Controller
      attr_accessor :document
      
      def inspect
        "<#{self.class}>"
      end
      
      module ModificationCallbacks
        def before_modify(start_offset, end_offset, text)
          raise "not implemented"
        end
      
        def after_modify
          raise "not implemented"
        end
      end
      
      module NewlineCallback
        def after_newline(line_ix)
          raise "not implemented"
        end
      end
      
      module CursorCallbacks
        def cursor_moved(offset)
          raise "not implemented"
        end
      end
    end
  end
end
