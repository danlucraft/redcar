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

        grid_data = Swt::Layout::GridData.new
        grid_data.grabExcessHorizontalSpace = true
        grid_data.horizontalAlignment = Swt::Layout::GridData::FILL
        @status_bar_widget = Swt::Widgets::Composite.new(@widget, Swt::SWT::NONE)
        @status_bar_widget.set_layout_data(grid_data)
        @status_bar_widget.set_layout(Swt::Layout::GridLayout.new(2, false))
        create_grammar_selector
        create_tab_stops_selector
        @edit_view.mate_text.add_grammar_listener do |new_grammar|
          @model.edit_view.set_grammar(new_grammar)
        end
        @widget.pack
      end
      
      def create_grammar_selector
        @combo = Swt::Widgets::Combo.new(@status_bar_widget, Swt::SWT::READ_ONLY)
        bundles  = JavaMateView::Bundle.bundles.to_a
        grammars = bundles.map {|b| b.grammars.to_a}.flatten
        items    = grammars.map {|g| g.name}.sort_by {|name| name.downcase }
        @combo.items = items.to_java(:string)
        
        @edit_view.mate_text.add_grammar_listener do |new_grammar|
          @combo.select(items.index(new_grammar))
        end
        
        @combo.add_selection_listener do |event|
          @edit_view.model.grammar = @combo.text
        end
        
        grammar = @edit_view.mate_text.parser.grammar.name
        @combo.select(items.index(grammar))
      end
      
      def create_tab_stops_selector
        @tabs_combo = Swt::Widgets::Combo.new(@status_bar_widget, Swt::SWT::READ_ONLY)
        tab_widths = %w(2 3 4 6 8)
        @tabs_combo.items = tab_widths.to_java(:string)
        @tabs_combo.select(tab_widths.index(EditView.tab_widths.for(@edit_view.model.grammar).to_s))
        @tabs_combo.add_selection_listener do |event|
          puts "selected tab width: #{@tabs_combo.text}"
          @model.edit_view.tab_width = @tabs_combo.text.to_i
        end
        
        @edit_view.model.add_listener(:tab_width_changed) do |new_value|
          @tabs_combo.select(tab_widths.index(new_value.to_s))
        end
      end
    end
  end
end
