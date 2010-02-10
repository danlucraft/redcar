
require 'auto_indenter/document_controller'

module Redcar
  class AutoIndenter
    
    def self.start
      Document.register_controller_type(AutoIndenter::DocumentController)
    end
    
    def self.tab_handlers
      [IndentTabHandler]
    end
    
    class IndentTabHandler
      def self.handle(edit_view)
        p IndentTabHandler, edit_view.document.length
      end
    end
  end
end
