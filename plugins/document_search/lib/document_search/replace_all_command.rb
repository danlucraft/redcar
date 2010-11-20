module DocumentSearch
  class ReplaceAllCommand < ReplaceCommand
    def execute
      replacement_text, startoff = nil
      count = 0
      sc = StringScanner.new(doc.get_all_text)
      doc.compound do
        while sc.scan_until(query)
          count += 1
          startoff = sc.pos - sc.matched_size
          text = doc.get_range(startoff, sc.matched_size)
          replacement_text = text.gsub(query, replace)
          doc.replace(sc.pos - sc.matched_size, sc.matched_size, replacement_text)
        end
      end
      if replacement_text && startoff
        doc.set_selection_range(startoff + replacement_text.length, startoff)
        doc.scroll_to_line(doc.line_at_offset(startoff))
      end
      count
    end
  end
end
