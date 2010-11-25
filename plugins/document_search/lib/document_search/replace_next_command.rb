module DocumentSearch
  class ReplaceNextCommand < ReplaceCommand
    # The current selection is usually not used for the next replacement, unless
    # it matches the query string, in which case we assume that the user meant replace it, too
    def start_position
      offsets = [doc.cursor_offset, doc.selection_offset]
      return offsets.min if query == doc.selected_text
      offsets.max
    end

    def execute
      sc = StringScanner.new(doc.get_all_text)
      sc.pos = start_position
      sc.scan_until(query) || sc.reset && sc.scan_until(query)

      return 0 unless sc.matched?
      startoff = sc.pos - sc.matched_size

      text = doc.get_range(startoff, sc.matched_size)
      replacement_text = text.gsub(query, replace)
      doc.replace(sc.pos - sc.matched_size, sc.matched_size, replacement_text)
      doc.set_selection_range(startoff + replacement_text.length, startoff)
      doc.scroll_to_line(doc.line_at_offset(startoff))
      1
    end
  end
end