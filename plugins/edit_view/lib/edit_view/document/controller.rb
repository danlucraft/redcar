
module Redcar
  class Document
    module Controller
      attr_accessor :document
      
      def inspect
        "<#{self.class}>"
      end
      
      # Called after every user action that modifies the document.
      # E.g. typing "a", moving up, running a search. NOT included
      # is modifications made by calling methods on Document, but they
      # are usually implied by the Commands that make them.
      #
      # @param [String|Symbol|DocumentCommand] This is a document action.
      def after_action(action)
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
