require File.expand_path("../vtab_label", __FILE__)

module Swt
  module Widgets
    class VTabItem
      attr_accessor :text, :control
      attr_reader :parent

      def initialize(parent, style)
        @parent = parent
        @parent.add_item(self)
      end

      def text= title
        @text = title
        @label.title = title
      end

      def control= control
        @control = control
        @control.visible = active?
        @control.layout_data = Swt::Layout::GridData.new.tap do |l|
          l.horizontalAlignment = Swt::Layout::GridData::FILL
          l.verticalAlignment = Swt::Layout::GridData::FILL
          l.grabExcessHorizontalSpace = true
          l.grabExcessVerticalSpace = true
          l.exclude = active?
        end
      end

      def draw_label(tab_area)
        @label = VTabLabel.new(self, tab_area, Swt::SWT::NONE)
      end

      # This way up to the parent
      def activate
        @parent.selection = self
      end

      def active= boolean
        @label.active = boolean
        if @control
          @control.visible = boolean
          @control.layout_data.exclude = !boolean
        end
      end

      def active?
        @label.active
      end

      def selection_color_options
        @parent.selection_color_options
      end

      def font= swt_font
        @label.font = swt_font
      end

      def font
        @label.font
      end

      def show_close= bool
        @label.show_close = bool
      end

      def show_close
        @label.show_close
      end

      def dispose
        @control.dispose
        @label.dispose
      end
    end
  end
end