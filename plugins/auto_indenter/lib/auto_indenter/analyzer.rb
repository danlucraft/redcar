
module Redcar
  class AutoIndenter
    class Analyzer
      attr_reader :rules
      
      def initialize(rules, doc, tab_width, soft_tabs)
        @rules, @doc, @tab_width, @soft_tabs = rules, doc, tab_width, soft_tabs
        @indentation = doc.indentation
      end
      
      def calculate_for_line(line_ix)
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

        if rules.unindented_line?(current_line)
          return 0
        end
        
        if rules.increase_indent?(previous_line)
          #p [:inc_indent]
          new_level += 1
        end
        if rules.decrease_indent?(current_line)
          #p [:dec_indent]
          new_level -= 1
        end
        if indent_next_line
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
              indent_next_line = rules.indent_next_line?(line)
            end
                
            previous_ix = index_of_previous_non_unindented_line(current)
            previous_line = @doc.get_line(previous_ix)
          
            if !rules.indent_next_line?(previous_line)
              return current, indent_next_line
            else
              current -= 1
            end
          end
        end
      end
      
      def index_of_previous_non_unindented_line(line_ix)
        current = line_ix - 1
        line = @doc.get_line(current)
        while current >= 0 and rules.unindented_line?(line)
          current -= 1
          line = @doc.get_line(current)
        end
        #p [:index_of_previous_non_unindented_line, line_ix, current]
        current
      end
      
    end
  end
end