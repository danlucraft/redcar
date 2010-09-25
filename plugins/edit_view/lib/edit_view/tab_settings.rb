module Redcar
  class EditView
    class TabSettings
      DEFAULT_SOFTNESS = true
      DEFAULT_TAB_WIDTH = 2
      DEFAULT_WORD_WRAP = false
      DEFAULT_SETTING_NAME = "Default"
      TAB_WIDTHS        = %w(2 3 4 5 6 8)
      DEFAULT_MARGIN_COLUMN = 80
      DEFAULT_MARGIN_PRESENT = false

      attr_reader :tab_widths, :softnesses, :word_wraps, :margin_columns
      attr_reader :show_margins
      attr_reader :show_invisibles, :show_line_numbers

      def initialize
        @tab_widths =
            {DEFAULT_SETTING_NAME => DEFAULT_TAB_WIDTH}.merge(
              EditView.storage['tab_widths'] || {})
        @softnesses =
            {DEFAULT_SETTING_NAME => DEFAULT_SOFTNESS}.merge(
              EditView.storage['softnesses'] || {})
        @word_wraps =
            {DEFAULT_SETTING_NAME => DEFAULT_WORD_WRAP}.merge(
              EditView.storage['word_wraps'] || {})
        @margin_columns = 
            {DEFAULT_SETTING_NAME => DEFAULT_MARGIN_COLUMN}.merge(
              EditView.storage['margin_columns'] || {})
        @show_margins =
            {DEFAULT_SETTING_NAME => DEFAULT_MARGIN_PRESENT}.merge(
              EditView.storage['show_margins'] || {})
        @show_invisibles   = !!EditView.storage['show_invisibles']
        @show_line_numbers = !!EditView.storage['show_line_numbers']
      end
      
      def width_for(grammar_name)
        tab_widths[grammar_name] || tab_widths[DEFAULT_SETTING_NAME]
      end
      
      def set_width_for(grammar_name, width)
        width = width.to_i
        if tab_widths[grammar_name] != width
          tab_widths[grammar_name] = width
          EditView.storage['tab_widths'] = tab_widths
        end
      end
      
      def softness_for(grammar_name)
        if softnesses[grammar_name] == nil
          softnesses[DEFAULT_SETTING_NAME]
        else
          softnesses[grammar_name]
        end
      end
      
      def set_softness_for(grammar_name, boolean)
        boolean = !!boolean
        if softnesses[grammar_name] != boolean
          softnesses[grammar_name] = boolean
          EditView.storage['softnesses'] = softnesses
        end
      end
      
      def word_wrap_for(grammar_name)
        if word_wraps[grammar_name] == nil
          word_wraps[DEFAULT_SETTING_NAME]
        else
          word_wraps[grammar_name]
        end
      end
      
      def set_word_wrap_for(grammar_name, boolean)
        boolean = !!boolean
        if word_wraps[grammar_name] != boolean
          word_wraps[grammar_name] = boolean
          EditView.storage['word_wraps'] = word_wraps
        end
      end
      
      def margin_column_for(grammar_name)
        margin_columns[grammar_name] || margin_columns[DEFAULT_SETTING_NAME]
      end
      
      def set_margin_column_for(grammar_name, column)
        if margin_columns[grammar_name] != column
          margin_columns[grammar_name] = column
          EditView.storage['margin_columns'] = margin_columns
        end
      end
      
      def show_margin_for(grammar_name)
        if show_margins[grammar_name] == nil
          show_margins[DEFAULT_SETTING_NAME]
        else
          show_margins[grammar_name]
        end
      end
      
      def set_show_margin_for(grammar_name, boolean)
        boolean = !!boolean
        if show_margins[grammar_name] != boolean
          show_margins[grammar_name] = boolean
          EditView.storage['show_margins'] = show_margins
        end
      end
      
      def show_invisibles?
        show_invisibles
      end
      
      def set_show_invisibles(bool)
        @show_invisibles = bool
        EditView.storage['show_invisibles'] = bool
      end

      def show_line_numbers?
        show_line_numbers
      end
      
      def set_show_line_numbers(bool)
        @show_line_numbers = bool
        EditView.storage['show_line_numbers'] = bool
      end

      def show_margin?
        show_margin
      end
      
      def set_show_margin(bool)
        @show_margin = bool
        EditView.storage['show_margin'] = bool
      end
    end
  end
end
