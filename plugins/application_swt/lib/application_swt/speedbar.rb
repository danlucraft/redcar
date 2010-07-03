module Redcar
  class ApplicationSWT
    class Speedbar
      include Redcar::ReentryHelpers
      
      attr_reader :widget
      
      def initialize(window, parent, model)
        @window_model = window
        @parent = parent
        @model = model
        create_widgets
        attach_key_listeners
        disable_menu_items
        if widget = focussable_widgets.first
          widget.set_focus
        end
        @handlers = Hash.new {|h,k| h[k] = []}
        @parent.layout
        @model.after_draw if @model.respond_to?(:after_draw)
      end
      
      def close
        @composite.dispose
        @parent.layout
      end
      
      def disable_menu_items
        key_strings = []
        @model.__items.each do |i|
          if i.respond_to?(:key)
            key_strings << i.key
          end
        end
        key_strings.uniq.each do |key_string|
          ApplicationSWT::Menu.disable_items(key_string)
        end
      end
      
      def num_columns
        @model.__items.select {|i| !i.is_a?(Redcar::Speedbar::KeyItem) }.length
      end
      
      def key_items
        @model.__items.select {|i| i.respond_to?(:key) and i.key }
      end
      
      def keyable_widgets
        @keyable_widgets ||= []
      end
      
      def focussable_widgets
        @focussable_widgets ||= []
      end
      
      def create_widgets
        create_bar_widget
        create_item_widgets
      end
      
      def create_bar_widget
        @composite = Swt::Widgets::Composite.new(@parent, Swt::SWT::NONE)
        grid_data = Swt::Layout::GridData.new
        grid_data.grabExcessHorizontalSpace = true
        grid_data.horizontalAlignment = Swt::Layout::GridData::FILL
      	@composite.setLayoutData(grid_data)
        layout = Swt::Layout::GridLayout.new(num_columns + 1, false)
        layout.verticalSpacing = 0
        layout.marginHeight = 0
        layout.marginTop = 5
        @composite.setLayout(layout)
        image = Swt::Graphics::Image.new(ApplicationSWT.display, Redcar::Speedbar.close_image_path)
        label = Swt::Widgets::Label.new(@composite, 0)
        label.set_image(image)
	
	    label.add_mouse_listener(MouseListener.new(self))
	  end
	  
    def execute_listener_in_model(item, *args)
      if item.listener
        begin
          @model.instance_exec(*args, &item.listener)
        rescue => err
          error_in_listener(err)
        end
      end
    end
    
	  def create_item_widgets
        @model.__items.each do |item|
          case item
          when Redcar::Speedbar::LabelItem
            label = Swt::Widgets::Label.new(@composite, 0)
            label.set_text(item.text)
            item.add_listener(:changed_text) do |new_text|
              label.set_text(item.text)
            end
          when Redcar::Speedbar::TextBoxItem
            edit_view = EditView.new
            item.edit_view = edit_view
            edit_view_swt = EditViewSWT.new(edit_view, @composite, :single_line => true)
            mate_text = edit_view_swt.mate_text
            mate_text.set_font(EditView.font, EditView.font_size)
            mate_text.getControl.set_text(item.value)
            mate_text.set_grammar_by_name "Ruby"
            mate_text.set_theme_by_name(EditView.theme)
            mate_text.set_root_scope_by_content_name("Ruby", "string.regexp.classic.ruby")
            gridData = Swt::Layout::GridData.new
            gridData.grabExcessHorizontalSpace = true
            gridData.horizontalAlignment = Swt::Layout::GridData::FILL
            mate_text.getControl.set_layout_data(gridData)
            edit_view.document.add_listener(:changed) do
              ignore(item.name) do
                item.value = edit_view.document.to_s
                execute_listener_in_model(item, item.value)
              end
            end
            item.add_listener(:changed_value) do |new_value|
              ignore(item.name) do
                mate_text.getControl.set_text(new_value)
              end
            end
            keyable_widgets << mate_text.getControl
            focussable_widgets << mate_text.getControl
          when Redcar::Speedbar::ButtonItem
            button = Swt::Widgets::Button.new(@composite, 0)
            button.set_text(item.text)
            button.add_selection_listener do
              execute_listener_in_model(item)
            end
            item.add_listener(:changed_text) do |new_text|
              button.set_text(item.text)
            end
            keyable_widgets << button
            focussable_widgets << button
          when Redcar::Speedbar::ComboItem
            combo = Swt::Widgets::Combo.new(@composite, Swt::SWT::READ_ONLY)
            combo.items = item.items.to_java(:string)
            if item.value
              combo.select(item.items.index(item.value))
            end
            combo.add_selection_listener do
              ignore(item.name) do
                item.value = combo.text
                execute_listener_in_model(item, item.value)
              end
            end
            item.add_listener(:changed_items) do |new_items|
              rescue_speedbar_errors do
                ignore(item.name) do
                  combo.items = item.items.to_java(:string)
                  item.value = nil
                end
              end
            end
            item.add_listener(:changed_value) do |new_value|
              rescue_speedbar_errors do
                ignore(item.name) do
                  combo.select(item.items.index(item.value))
                end
              end
            end
            keyable_widgets    << combo
            focussable_widgets << combo
          when Redcar::Speedbar::ToggleItem
            button = Swt::Widgets::Button.new(@composite, Swt::SWT::CHECK)
            button.set_text(item.text)
            button.set_selection(!!item.value)
            button.add_selection_listener do
              item.value = button.get_selection
              execute_listener_in_model(item, item.value)
            end
            item.add_listener(:changed_text) do |new_text|
              rescue_speedbar_errors do
                button.set_text = new_text
              end
            end
            item.add_listener(:changed_value) do |new_value|
              rescue_speedbar_errors do
                button.set_selection(!!new_value)
              end
            end
            keyable_widgets    << button
            focussable_widgets << button
          end
        end
      end
      
      class KeyListener
        def initialize(speedbar)
          @speedbar = speedbar
        end
        
        def key_pressed(e)
        end
        
        def key_released(e)
          @speedbar.key_press(e)
        end
      end
      
      class MouseListener
        def initialize(speedbar)
          @speedbar = speedbar
        end
        
        def mouse_down(*_); end
        
        def mouse_up(*_)
          @speedbar.close_pressed
        end
        
        def mouse_double_click(*_); end
      end
      
      def attach_key_listeners
        keyable_widgets.each do |widget|
          widget.add_key_listener(KeyListener.new(self))
        end
      end
      
      def close_pressed
        @window_model.close_speedbar
      end
      
      def key_press(e)
        key_string = Menu::BindingTranslator.key_string(e)
        if key_string == "\e"
          @window_model.close_speedbar
          e.doit = false
        end
        key_items.each do |key_item|
          if Menu::BindingTranslator.matches?(key_string, key_item.key)
            e.doit = false
            begin
              @model.instance_exec(&key_item.listener)
            rescue Object => err
              error_in_listener(err)
            end
          end
        end
      end
      
      def rescue_speedbar_errors
        begin
          yield
        rescue Object => e
          puts "*** Error in speedbar"
          puts e.class.to_s + ": " + e.message
          puts e.backtrace
        end
      end
      
      def error_in_listener(e)
        puts "*** Error in speedbar listener: #{e.message}"
        puts e.backtrace.map {|l| "    " + l}
      end
    end
  end
end

