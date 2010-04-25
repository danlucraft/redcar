
module Redcar
  class AutoIndenter
    class Rules
      def initialize(increase_indent_pattern, 
                      decrease_indent_pattern,
                      indent_next_line_pattern=nil,
                      unindented_line_pattern=nil)
        @increase_indent_pattern  = increase_indent_pattern
        @decrease_indent_pattern  = decrease_indent_pattern
        @indent_next_line_pattern = indent_next_line_pattern
        @unindented_line_pattern  = unindented_line_pattern
      end
      
      def increase_indent?(line)
        if @increase_indent_pattern
          !!(line =~ @increase_indent_pattern)
        end
      end
      
      def decrease_indent?(line)
        if @decrease_indent_pattern
          !!(line =~ @decrease_indent_pattern)
        end
      end
      
      def indent_next_line?(line)
        if @indent_next_line_pattern
          !!(line =~ @indent_next_line_pattern)
        end
      end
      
      def unindented_line?(line)
        if @unindented_line_pattern
          !!(line =~ @unindented_line_pattern)
        end
      end
    end
  end
end

