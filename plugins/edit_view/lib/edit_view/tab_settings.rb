module Redcar
  class EditView
    class TabSettings
      DEFAULT_SOFTNESS = true
      DEFAULT_TAB_WIDTH = 2
      DEFAULT_SETTING_NAME = "Default"
      TAB_WIDTHS        = %w(2 3 4 5 6 8)
      
      attr_reader :tab_widths, :softnesses, :show_invisibles
    
      def initialize
        @tab_widths =
            {DEFAULT_SETTING_NAME => DEFAULT_TAB_WIDTH}.merge(
              EditView.storage['tab_widths'] || {})
        @softnesses =
            {DEFAULT_SETTING_NAME => DEFAULT_SOFTNESS}.merge(
              EditView.storage['softnesses'] || {})
        @show_invisibles = !!EditView.storage['show_invisibles']
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
        softnesses[grammar_name] || softnesses[DEFAULT_SETTING_NAME]
      end
      
      def set_softness_for(grammar_name, boolean)
        boolean = !!boolean
        if softnesses[grammar_name] != boolean
          softnesses[grammar_name] = boolean
          EditView.storage['softnesses'] = softnesses
        end
      end
      
      def show_invisibles?
        show_invisibles
      end
      
      def set_show_invisibles(bool)
        @show_invisibles = bool
        EditView.storage['show_invisibles'] = bool
      end
    end
  end
end
