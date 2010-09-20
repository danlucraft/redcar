module Redcar
  class EditView

    class AlignAssignmentCommand < Redcar::DocumentCommand
      def execute
        operators = /(\|{0,2}[+-\/%*!]?={1,3}[>~]?)/
        relevant_line_pattern = /^([^=]+?)#{operators}(.*$)/o

        #fix the selection. this command operates on whole lines
        start_offset, end_offset = offsets_for_whole_lines(doc.cursor_offset, doc.selection_offset)

        doc.set_selection_range(start_offset, end_offset)

        doc.replace_selection do |old_text|

          #get max left-hand and right-hand sides in 1 pass
          lengths = old_text.lines.map do |line|
            [line =~ operators || -1, $1 && $1.size || -1]
          end
          lhs_len = lengths.reduce(0){|memo, len| len.first > memo ? len.first : memo}
          rhs_len = lengths.reduce(0){|memo, len| len.last > memo ? len.last : memo}

          #now replace the first token of the relevant lines
          old_text.lines.map do |line|
            line.chomp!
            if line =~ relevant_line_pattern
              "%-#{lhs_len}s%#{rhs_len}s %s" % [$1, $2, $3.strip]
            else
              line
            end
          end.join("\n")
        end
      end

      def offsets_for_whole_lines(start_offset, end_offset)
        #are the selections in the right order?
        if start_offset > end_offset
          end_offset, start_offset = start_offset, end_offset
        end

        start_index = doc.line_at_offset(start_offset)
        end_index = doc.line_at_offset(end_offset)

        #is the selection of the last line empty?
        if end_offset == doc.offset_at_line(end_index)
          end_index -= 1
        end

        start_offset = doc.offset_at_line(start_index)
        end_offset = doc.offset_at_inner_end_of_line(end_index)
        return [start_offset, end_offset]
      end
    end
  end
end
