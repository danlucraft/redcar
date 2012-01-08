module Redcar
  class EditView

    class ToggleSoftTabsCommand < Redcar::EditTabCommand
      def execute
        tab.edit_view.soft_tabs = !tab.edit_view.soft_tabs?
      end
    end
      
    class ToggleWordWrapCommand < Redcar::EditTabCommand
      def execute
        tab.edit_view.word_wrap = !tab.edit_view.word_wrap?
      end
    end
      
    class ToggleShowMarginCommand < Redcar::EditTabCommand
      def execute
        tab.edit_view.show_margin = !tab.edit_view.show_margin?
      end
    end
    
    class SetTabWidthCommand < Redcar::EditTabCommand
      class << self
        attr_accessor :width
      end
      
      def execute
        tab.edit_view.tab_width = self.class.width.to_i
      end
    end
    
    class SetMarginColumnCommand < Redcar::EditTabCommand
      def execute
        response = Application::Dialog.input("Margin Column", "Enter new margin column:", tab.edit_view.margin_column) do |text|
          if text !~ /^\d+$/
            "must be an integer number"
          end
        end
        value = response[:value].to_i
        tab.edit_view.margin_column = [[value, 200].min, 5].max
      end
    end
      
  end
end