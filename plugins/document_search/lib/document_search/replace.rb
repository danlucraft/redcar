module DocumentSearch
  class ReplaceNextCommand < Redcar::DocumentCommand

    attr_reader :query, :replace, :search_method

    def initialize(query, replace, search_method)
      @query, @replace, @search_method = query, replace, search_method
    end

    def body
      Search.method(search_method)
    end

    def execute
      # The current selection is usually not used for the next replacement, unless
      # it matches the query string, in which case we assume that the user meant replace it, too
      offsets = [doc.cursor_offset, doc.selection_offset]
      if query == doc.selected_text
        latest_point = offsets.min
      else
        latest_point = offsets.max
      end

      # Get the current line and then get the line segment from the cursor to the end of the line
      curr_line_number = doc.line_at_offset(latest_point)
      cursor_line_offset = latest_point - doc.offset_at_line(curr_line_number)
      curr_line = doc.get_line(curr_line_number)
      line_seg = curr_line[cursor_line_offset..-1]

      # Call the search method passed by the caller
      new_line, startoff, endoff = body.call(line_seg, query, replace)

      # The passed in method returns the string replacement or nil
      if new_line
        # Add the replacment to the end of the line, and then replace in the document
        curr_line[cursor_line_offset..-1] = new_line
        doc.replace_line(doc.cursor_line, curr_line.chomp)
        line_offset = doc.offset_at_line(doc.cursor_line)
        doc.set_selection_range(cursor_line_offset + line_offset + startoff, cursor_line_offset + line_offset + endoff)
        return 1
      end

      #Look at the rest of the lines starting at the next line
      start_line = doc.cursor_line
      (start_line+1..doc.line_count-1).each do |i|
        new_line, startoff, endoff = body.call(doc.get_line(i), query, replace)
        if new_line
          doc.replace_line(i, new_line.chomp)
          line_offset = doc.offset_at_line(i)
          doc.set_selection_range(line_offset + startoff, line_offset + endoff)
          doc.ensure_visible(doc.offset_at_line(i))
          return 1
        end
      end

      #Look at the rest of the lines starting at the beginning
      start_line = doc.cursor_line
      (0..start_line-1).each do |i|
        new_line, startoff, endoff = body.call(doc.get_line(i), query, replace)

        if new_line
          doc.replace_line(i, new_line.chomp)
          line_offset = doc.offset_at_line(i)
          doc.set_selection_range(line_offset + startoff, line_offset + endoff)
          doc.ensure_visible(doc.offset_at_line(i))
          return 1
        end
      end
      0
    end
  end

  class ReplaceAllCommand < Redcar::DocumentCommand

    attr_reader :query, :replace, :search_method

    # Replace All starts at the begnning of the doc and iterates over all of the lines.
    def initialize(query, replace, search_method)
      @query, @replace, @search_method = query, replace, search_method
    end

    def body
      Search.method(search_method)
    end

    def execute
      count = 0
      last_match_line = nil
      startoff = nil
      endoff = nil
      doc.compound do
        (0..(doc.line_count-1)).each do |i|
          begin
            line, a, b = body.call(doc.get_line(i), query, replace)
            if line
              startoff = a
              endoff = b
              last_match_line = i
              doc.replace_line(i, line.chomp)
              count += 1
            end
          end
        end
      end
      if last_match_line
        line_offset = doc.offset_at_line(last_match_line)
        doc.set_selection_range(line_offset + startoff, line_offset + endoff)
        doc.ensure_visible(doc.offset_at_line(last_match_line))
      end
      count
    end
  end
end