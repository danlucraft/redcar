
module Redcar
  class Document
    module Controller
      def initialize(document)
        @document = document
      end
      
      def document
        @document
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
    end
  end
end
