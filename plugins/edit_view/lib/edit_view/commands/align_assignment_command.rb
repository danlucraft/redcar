module Redcar
  class EditView

    class AlignAssignmentCommand < Redcar::DocumentCommand
      def execute
        relevant_line_pattern = /^([^=]+)([^-+<>=!%\/|&*^]=(?!=|~).*$)/
        operators = /[^-+<>=!%\/|&*^]=(?!=|~)/

        doc.replace_selection do |old_text|
          #find the longest length of the relevant lines
          length = old_text.lines.map{|line| line =~ operators }.compact.max

          #now replace the first token of the relevant lines
          old_text.lines.map do |line|
            line.chomp!
            if line =~ relevant_line_pattern
              "%-#{length}s%s" % [$1, $2]
            else
              line
            end
          end.join("\n")
        end
      end
    end
  end
end
