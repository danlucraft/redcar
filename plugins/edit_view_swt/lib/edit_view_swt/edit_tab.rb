module Redcar
  class EditViewSWT
    class Tab < ApplicationSWT::Tab
      include Redcar::Observable
      
      attr_reader :item, :edit_view
      
      def initialize(model, notebook)
        super
        @model.add_listener(:changed_title) { |title| @item.text = title }
      end
      
      def create_tab_widget
        @edit_view = EditViewSWT.new(model.edit_view, self)
        @item.control = @edit_view.widget
      end
      
      # Focuses the CTabItem within the CTabFolder, and gives the keyboard
      # focus to the EditViewSWT.
      def focus
        super
        edit_view.focus
      end
      
      # Close the EditTab, disposing of any resources along the way.
      def close
        @edit_view.dispose
        super
      end
    end
  end
end
