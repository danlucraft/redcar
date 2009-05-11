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
        line_start = doc.cursor_line      
        c = doc.cursor_offset
        c.downto(line_start){|i|
          doc.select(i, i+1)
          low = i+1
          if (doc.selection == ' ' && i != c)
            low = i+1
            break
          elsif(i == line_start)
            low = line_start
            break
          end
        }
        
        line_end = (doc.get_line).length
        c.upto(line_end){|i|
          doc.select(i-1, i)
          if (doc.selection == ' ') 
            high = i-1
            break
          elsif (i == line_end)
            high = line_end
            break
          end
        }
        doc.select(low,high)
        doc.replace_selection((doc.selection).upcase)
        doc.select(c,c)
      end
    end  
  end
end
