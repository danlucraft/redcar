module Redcar
  class EditView

    class AlignAssignmentCommand < Redcar::DocumentCommand
      OPERATORS = /(\|{0,2}[+-\/%*!&]?={1,3}[>~]?)/
      RELEVANT_LINE_PATTERN = /^([^=]+?)#{OPERATORS}(.*$)/o
      
      def execute
        doc.expand_selection_to_full_lines
        doc.replace_selection(&AlignAssignmentCommand.method(:align))
      end
      
      def self.align(text)
        # get max left-hand and right-hand sides in 1 pass
        lengths = text.lines.map do |line|
          [line =~ OPERATORS || -1, $1 && $1.size || -1]
        end
        
        lhs_len = lengths.reduce(0) { |memo, len| len.first > memo ? len.first : memo }
        rhs_len = lengths.reduce(0) { |memo, len| len.last > memo ? len.last : memo }

        # now replace the first token of the relevant lines
        text.lines.map do |line|
          line.chomp!
          if line =~ RELEVANT_LINE_PATTERN
            "%-#{lhs_len}s%#{rhs_len}s %s" % [$1, $2, $3.strip]
          else
            line
          end
        end.join("\n")
      end

      def adjust_selection_to_full_lines(start_offset, end_offset)
        #are the selections in the right order?
        if start_offset > end_offset
          end_offset, start_offset = start_offset, end_offset
        end

        start_index = doc.line_at_offset(start_offset)
        end_index   = doc.line_at_offset(end_offset)

        # is the selection of the last line empty?
        if end_offset == doc.offset_at_line(end_index)
          end_index -= 1
        end

        start_offset = doc.offset_at_line(start_index)
        end_offset = doc.offset_at_inner_end_of_line(end_index)
        
        doc.set_selection_range(start_offset, end_offset)
      end
    end
  end
end
