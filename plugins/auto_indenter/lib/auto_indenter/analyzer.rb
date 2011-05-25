
module Redcar
  class AutoIndenter
    class Analyzer
      attr_reader :rules
      
      def initialize(rules, doc, tab_width, soft_tabs)
        @rules, @doc, @tab_width, @soft_tabs = rules, doc, tab_width, soft_tabs
        @indentation = doc.indentation
      end
      
      def calculate_for_line(line_ix, typing=false)
        return 0 if line_ix == 0
        #p [:line_ix, line_ix]
        current_line  = @doc.get_line(line_ix)
        previous_ix, indent_next_line = index_of_previous_normally_indented(line_ix)
        #p [:previous_ix, previous_ix, indent_next_line]
        previous_line = @doc.get_line(previous_ix)
        current_level = @indentation.get_level(previous_ix)
        new_level     = current_level
        #p [:previous_line, previous_line]
        #p [:current_line, current_line]
        #p [:current_level, current_level]

        if !typing and rules.unindented_line?(current_line)
          #p [:unindented_line]
          return @indentation.get_level(line_ix)
        end

        if rules.increase_indent?(previous_line)
          #p [:inc_indent]
          new_level += 1
        end
        if rules.decrease_indent?(current_line)
          #p [:dec_indent]
          new_level -= 1
        end
        if !typing and indent_next_line and !rules.increase_indent?(current_line)
          #p [:indent_next_line]
          new_level += 1
        end

        #p [:new_level, new_level]
        new_level
      end
      
      def index_of_previous_normally_indented(line_ix)
        current = line_ix - 1
        indent_next_line = nil
        loop do
          if current == 0
            return 0, indent_next_line
          end
          line = @doc.get_line(current)
          if rules.unindented_line?(line)
            current -= 1
          else
            if indent_next_line == nil
              #p [:indent_next_line?, line, rules.indent_next_line?(line)]
              indent_next_line = rules.indent_next_line?(line)
            end
            previous_ix = index_of_previous_non_unindented_line(current)
            if previous_ix < 0
              return current, indent_next_line
            else
              previous_line = @doc.get_line(previous_ix)
            
              if rules.indent_next_line?(previous_line) and !rules.increase_indent?(line)
                current -= 1
              else
                return current, indent_next_line
              end
            end
          end
        end
      end
      
      def index_of_previous_non_unindented_line(line_ix)
        current = line_ix - 1
        while current >= 0 and 
              line = @doc.get_line(current) and 
              rules.unindented_line?(line)
          current -= 1
        end
        #p [:index_of_previous_non_unindented_line, line_ix, current]
        current
      end
      
      def expand_block?(line_ix)
        return false if line_ix == 0
        
        prev_line = @doc.get_line(line_ix - 1)
        next_line = @doc.get_line(line_ix)
        
        rules.increase_indent?(prev_line) and 
          rules.decrease_indent?(next_line)
      end
    end
  end
end