module Redcar
  class EditView
    class TabWidths
      DEFAULT_TAB_WIDTH = 2
      TAB_WIDTHS        = %w(2 3 4 5 6 8)
      
      attr_reader :tab_widths
    
      def initialize
        @tab_widths = EditView.storage['tab_widths'] || {}
      end
      
      def for(grammar_name)
        tab_widths[grammar_name] || DEFAULT_TAB_WIDTH
      end
      
      def set_for(grammar_name, width)
        if tab_widths[grammar_name] != width
          tab_widths[grammar_name] = width
          EditView.storage['tab_widths'] = tab_widths
        end
      end
    end
  end
end