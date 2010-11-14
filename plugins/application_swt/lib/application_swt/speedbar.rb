require 'application_swt/speedbar/button_item'
require 'application_swt/speedbar/combo_item'
require 'application_swt/speedbar/label_item'
require 'application_swt/speedbar/slider_item'
require 'application_swt/speedbar/text_box_item'
require 'application_swt/speedbar/toggle_item'

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
          swt_klass = self.class.const_get(item.class.to_s.split("::").last)
          swt_klass.new(self, @composite, item)
        end
      end

      class KeyListener
        def initialize(speedbar)
          @speedbar = speedbar
        end

        def key_pressed(e)
          @speedbar.key_press(e)
        end

        def key_released(e)
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
        return if Application::Dialog.in_dialog?
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
          if e.class.name == "TestingError"
            raise e
          else
            puts "*** Error in speedbar"
            puts e.class.to_s + ": " + e.message
            puts e.backtrace
          end
        end
      end

      def error_in_listener(e)
        if e.class.name == "TestingError"
          raise e
        else
          puts "*** Error in speedbar listener: #{e.message}"
          puts e.backtrace.map {|l| "    " + l}
        end
      end
    end
  end
end

