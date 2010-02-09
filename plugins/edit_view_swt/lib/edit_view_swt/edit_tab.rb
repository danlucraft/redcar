module Redcar
  class EditViewSWT
    class Tab < ApplicationSWT::Tab
      include Redcar::Observable
      
      attr_reader :item, :edit_view
      
      def initialize(model, notebook)
        super
        @model.add_listener(:changed_title) { |title| @item.text = title }
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
        @combo.dispose
        @widget.dispose
        super
      end
      
      private
      
      def create_tab_widget
        @widget = Swt::Widgets::Composite.new(notebook.tab_folder, Swt::SWT::NONE)
        layout = Swt::Layout::GridLayout.new(1, false)
        layout.verticalSpacing = 0
        layout.marginHeight = 0
        layout.horizontalSpacing = 0
        layout.marginWidth = 0
        @widget.layout = layout
        @edit_view = EditViewSWT.new(model.edit_view, @widget)
        
        grid_data = Swt::Layout::GridData.new(
                      Swt::Layout::GridData::FILL_BOTH | 
                      Swt::Layout::GridData::VERTICAL_ALIGN_FILL |
                      Swt::Layout::GridData::HORIZONTAL_ALIGN_FILL)
        @edit_view.mate_text.get_control.parent.set_layout_data(grid_data)

        @item.control = @widget
        create_grammar_selector
        @edit_view.mate_text.add_grammar_listener do |new_grammar|
          @model.edit_view.set_grammar(new_grammar)
        end
        @widget.pack
      end
      
      def create_grammar_selector
        @combo = Swt::Widgets::Combo.new @widget, Swt::SWT::READ_ONLY
        bundles  = JavaMateView::Bundle.bundles.to_a
        grammars = bundles.map {|b| b.grammars.to_a}.flatten
        items    = grammars.map {|g| g.name}.sort_by {|name| name.downcase }
        @combo.items = items.to_java(:string)
        
        @edit_view.mate_text.add_grammar_listener do |new_grammar|
          @combo.select(items.index(new_grammar))
        end
        
        @combo.add_selection_listener do |event|
          @edit_view.mate_text.set_grammar_by_name(@combo.text)
        end
        
        grammar = @edit_view.mate_text.parser.grammar.name
        @combo.select(items.index(grammar))
        
        @widget.pack
      end
    end
  end
end
