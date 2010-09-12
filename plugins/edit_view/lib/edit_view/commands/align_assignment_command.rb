module Redcar
  class EditView

    class AlignAssignmentCommand < Redcar::DocumentCommand
      def execute
        relevant_line_pattern = /^([^=]+)([^-+<>=!%\/|&*^]=(?!=|~))(.*$)/
        operators = /[^-+<>=!%\/|&*^]=(?!=|~)/

        #fix the selection. this command operates on whole lines
        start_offset, end_offset = offsets_for_whole_lines(doc.cursor_offset, doc.selection_offset)

        doc.set_selection_range(start_offset, end_offset)

        doc.replace_selection do |old_text|
          #find the longest length of the relevant lines
          length = old_text.lines.map{|line| line =~ operators }.compact.max

          #now replace the first token of the relevant lines
          old_text.lines.map do |line|
            line.chomp!
            if line =~ relevant_line_pattern
              "%-#{length}s%s %s" % [$1, $2, $3.strip]
            else
              line
            end
          end.join("\n")
        end
      end

      def offsets_for_whole_lines(start_offset, end_offset)
        start_index = doc.line_at_offset(doc.cursor_offset)
        end_index = doc.line_at_offset(doc.selection_offset)

        #is the selection of the last line empty?
        if doc.selection_offset == doc.offset_at_line(end_index)
          end_index -= 1
        end

        start_offset = doc.offset_at_line(start_index)
        end_offset = doc.offset_at_inner_end_of_line(end_index)
        return [start_offset, end_offset]
      end
    end
  end
end
