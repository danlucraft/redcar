module Redcar
  class EditView
    class InfoSpeedbar < Speedbar
      def self.grammar_names
        bundles  = JavaMateView::Bundle.bundles.to_a
        grammars = bundles.map {|b| b.grammars.to_a}.flatten
        items    = grammars.map {|g| g.name}.sort_by {|name| name.downcase }
      end
      
      combo :grammar do |new_grammar|
        @tab.edit_view.grammar = new_grammar
      end
      
      combo :tab_width, TabSettings::TAB_WIDTHS, TabSettings::DEFAULT_TAB_WIDTH do |new_tab_width|
        @tab.edit_view.tab_width = new_tab_width.to_i
      end
      
      toggle :soft_tabs, "Soft Tabs", nil, true do |new_value|
        @tab.edit_view.soft_tabs = new_value
      end
      
      toggle :word_wrap, "Word Wrap", nil, false do |new_value|
        @tab.edit_view.word_wrap = new_value
      end
      
      label :margin_column_label, "Margin:"
      textbox :margin_column, TabSettings::DEFAULT_MARGIN_COLUMN.to_s do |new_value|
        @tab.edit_view.margin_column = [new_value.to_i, 5].max
      end
      
      def initialize(command, tab)
        @command = command
        tab_changed(tab)
      end
      
      def tab_changed(new_tab)
        if @tab
          remove_handlers
        end
        if new_tab.is_a?(EditTab)
          @tab = new_tab
          grammar.items = InfoSpeedbar.grammar_names
          grammar.value = @tab.edit_view.grammar
          tab_width.value = @tab.edit_view.tab_width.to_s
          soft_tabs.value = @tab.edit_view.soft_tabs?
          word_wrap.value = @tab.edit_view.word_wrap?
          margin_column.value = @tab.edit_view.margin_column.to_s
          @width_handler = @tab.edit_view.add_listener(:tab_width_changed) do |new_value|
            tab_width.value = new_value.to_s
          end
          @margin_column_handler = @tab.edit_view.add_listener(:margin_column_changed) do |new_value|
            margin_column.value = new_value.to_s
          end
          @softness_handler = @tab.edit_view.add_listener(:softness_changed) do |new_value|
            soft_tabs.value = new_value
          end
          @word_wrap_handler = @tab.edit_view.add_listener(:word_wrap_changed) do |new_value|
            word_wrap.value = new_value
          end
          @grammar_handler = @tab.edit_view.add_listener(:grammar_changed) do |new_grammar|
            grammar.value = new_grammar
          end
        end
      end
      
      def remove_handlers
        @tab.edit_view.remove_listener(@width_handler)
        @tab.edit_view.remove_listener(@grammar_handler)
        @tab.edit_view.remove_listener(@softness_handler)
        @tab.edit_view.remove_listener(@word_wrap_handler)
        @tab.edit_view.remove_listener(@margin_column_handler)
      end        
      
      def close
        if @tab
          remove_handlers
        end
      end
    end
    
    class InfoSpeedbarCommand < Redcar::EditTabCommand
      def execute
        @speedbar = InfoSpeedbar.new(self, tab)
        win.open_speedbar(@speedbar)
      end
    end
  end
end