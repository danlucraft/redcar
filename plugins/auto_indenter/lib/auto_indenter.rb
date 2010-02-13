
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
        doc = edit_view.document
        line = doc.get_line(doc.cursor_line)
        if edit_view.soft_tabs?
          next_tab_stop_offset = (doc.cursor_line_offset/edit_view.tab_width + 1)*edit_view.tab_width
          insert_string = " "*(next_tab_stop_offset - doc.cursor_line_offset)
          doc.insert(doc.cursor_offset, insert_string)
          doc.cursor_offset = doc.cursor_offset + insert_string.length
        else
          doc.insert(doc.cursor_offset, "\t")
          doc.cursor_offset += 1
        end
      end
    end
  end
end
