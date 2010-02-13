
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
        return false unless edit_view.soft_tabs?
        doc = edit_view.document
        line = doc.get_line(doc.cursor_line)
        before_line = line[0...doc.cursor_line_offset]
        if before_line =~ /^\s*$/
          insert_string = " "*edit_view.tab_width
          doc.insert(doc.cursor_offset, insert_string)
          doc.cursor_offset = doc.cursor_offset + insert_string.length
        end
      end
    end
  end
end
