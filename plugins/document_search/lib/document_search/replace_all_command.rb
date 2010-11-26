module DocumentSearch
  class ReplaceAllCommand < ReplaceCommand
    def execute
      startoff, endoff = nil
      text = doc.get_all_text
      count = 0
      sc = StringScanner.new(text)
      while sc.scan_until(query)
        count += 1

        startoff = sc.pos - sc.matched_size
        replacement_text = text.slice(startoff, sc.matched_size).gsub(query, replace)
        endoff = startoff + replacement_text.length

        text[startoff...sc.pos] = replacement_text
        sc.string = text
        sc.pos = startoff + replacement_text.length
      end
      if count > 0
        doc.text = text
        doc.set_selection_range(startoff + replacement_text.length, startoff)
        doc.scroll_to_line(doc.line_at_offset(startoff))
      end
      count
    end
  end
end
