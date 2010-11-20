module DocumentSearch
  class ReplaceAllCommand < ReplaceCommand
    def execute
      count = 0
      doc.compound do
        sc = StringScanner.new(doc.get_all_text)
        while sc.scan(query)
          count += 1
          startoff = sc.pos - sc.matched_size
          text = doc.get_range(startoff, sc.matched_size)
          replacement_text = text.gsub(query, replace)
          doc.replace(sc.pos - sc.matched_size, sc.matched_size, replacement_text)
          doc.set_selection_range(startoff, replacement_text.length)
          doc.scroll_to_line(doc.line_at_offset(startoff))
        end
      end
      count
    end
  end
end
