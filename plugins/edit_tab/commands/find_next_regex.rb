module Redcar
  class FindNextRegex < Redcar::EditTabCommand
    def initialize(re, fa=nil)
      @re = re
      @fa = fa
    end

    def to_s
      "#{self.class}: @re=#{@re.inspect}"
    end

    def execute
      # first search the remainder of the current line
      curr_line = doc.get_line.to_s
      curr_line = curr_line[doc.cursor_line_offset..-1]
      if curr_line =~ @re
        line_iter = doc.line_start(doc.cursor_line)
        startoff = line_iter.offset + $`.length+doc.cursor_line_offset
        endoff   = startoff + $&.length
        doc.select(startoff, endoff)
      else
        # next search the rest of the lines
        line_num = doc.cursor_line+1
        curr_line = doc.get_line(line_num)
        until !curr_line or found = (curr_line.to_s =~ @re)
          line_num += 1
          curr_line = doc.get_line(line_num)
        end
        if found
          line_iter = doc.line_start(line_num)
          startoff = line_iter.offset + $`.length
          endoff   = startoff + $&.length
          doc.select(startoff, endoff)
          unless tab.view.cursor_onscreen?
            tab.view.scroll_mark_onscreen(doc.cursor_mark)
          end
        end
        if !doc.get_line(line_num) && @fa
          doc.cursor = 0
          execute
        end
      end
    end
  end
end
