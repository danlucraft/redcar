
module Redcar
  class Document
    class Indentation
      def initialize(doc, tab_width, soft_tabs)
        @doc, @tab_width, @soft_tabs = doc, tab_width, soft_tabs
      end
      
      def get_level(ix)
        whitespace_prefix(ix).scan(indent_consuming_regex).length
      end
      
      def whitespace_prefix(ix)
        line = @doc.get_line(ix)
        line.match(/^(\s*)([^\s]|$)/)[1].chomp
      end
      
      def set_level(ix, level)
        offset = @doc.offset_at_line(ix)
        prefix = whitespace_prefix(ix)
        if @soft_tabs
          @doc.replace(offset, prefix.length, " "*@tab_width*level)
        else
          @doc.replace(offset, prefix.length, "\t"*level)
        end
      end
      
      def trim_trailing_whitespace(ix)
        # don't have to check on delimiter at the end, @doc does that
        @doc.replace_line(ix, @doc.get_line(ix).rstrip)
      end
      
      private
      
      def indent_consuming_regex
        /( {0,#{@tab_width - 1}}\t| {#{@tab_width}})/
      end
    end
  end
end
