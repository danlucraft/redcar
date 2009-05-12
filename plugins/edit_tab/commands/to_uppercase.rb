module Redcar
  class ToUppercase < Redcar::EditTabCommand
    key "Ctrl+U"

    def execute
      if doc.selection?
        #convert selection to uppercase
        doc.replace_selection((doc.selection).upcase)
      else
        #convert current word to uppercase
        low = high = 0
        
        line_cursor = doc.cursor_line_offset
        doc_cursor = doc.cursor_offset
        
        line_start = doc.line_start(doc.cursor_line).line_index   
        line_end = doc.line_end1(doc.cursor_line).line_index
        line_start_offset = line_cursor - line_start
        line_end_offset = line_end - line_cursor
        
        doc_line_start = doc_cursor - line_start_offset
        doc_line_end = doc_cursor + line_end_offset  
        
        doc_cursor.downto(doc_line_start){|i|
          doc.select(i, i+1)
          if (doc.selection == ' ' && i != doc_cursor)
            low = i+1
            break
          elsif(i == doc_line_start)
            low = doc_line_start
            break
          end
        }
        
        doc_cursor.upto(doc_line_end){|i|
          doc.select(i-1, i)
          if (doc.selection == ' ' && i != doc_cursor) 
            high = i-1
            break
          elsif (i == doc_line_end)
            high = doc_line_end
            break
          end
        }
        doc.select(low,high)
        doc.replace_selection((doc.selection).upcase)
        doc.select(doc_cursor,doc_cursor)
      end
    end  
  end
end
