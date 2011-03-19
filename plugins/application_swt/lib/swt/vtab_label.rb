require File.expand_path("../graphics_utils", __FILE__)

module Swt
  module Widgets
    class VTabLabel
      attr_reader :active, :title, :show_close
      attr_accessor :font

      include Swt::Events::MouseListener
      include Swt::Events::MouseTrackListener

      ICON_PADDING = 3

      def close_icon
        @@close_icon ||= Redcar::ApplicationSWT::Icon.swt_image(:close)
      end

      def initialize(tab, parent, style)
        @label = Swt::Widgets::Label.new(parent, style)
        @active = false
        @tab = tab
        @parent = parent
        @title = ""
        @icon = nil
        @show_close = false

        @label.image = label_image
        @label.add_paint_listener { |event| event.gc.draw_image(label_image, 0, 0) }
        @label.add_mouse_listener(self)
        self.show_close = true
      end

      def label_image
        display = Swt::Widgets::Display.current
        unless @img
          @img = GraphicsUtils.create_rotated_text(@title, @font, @parent.foreground, @parent.background, Swt::SWT::UP) do |gc, extent|
            fg, bg = gc.foreground, gc.background
            if @active
              options = @tab.selection_color_options
              options[:percents].each_with_index do |p, idx|
                gc.foreground = options[:colors][idx]
                gc.background = options[:colors][idx + 1]
                if options[:vertical]
                  h = idx > 0 ? extent.height * options[:percents][idx - 1] : 0
                  gc.fill_gradient_rectangle(0, h, extent.width, extent.height * p, true)
                else
                  w = idx > 0 ? extent.width * options[:percents][idx - 1] : 0
                  gc.fill_gradient_rectangle(w, 0, extent.width * p, extent.height, false)
                end
              end
            else
              gc.fill_rectangle(0, 0, extent.width, extent.height)
            end
            gc.foreground = display.get_system_color(Swt::SWT::COLOR_WIDGET_NORMAL_SHADOW)
            gc.draw_rectangle(0, 0, extent.width - 1, extent.height - 1)
            gc.foreground, gc.background = fg, bg
          end
          overlay_icon(@icon, @img)
        end
        @img
      end

      def overlay_icon(icon, image)
        return unless icon
        gc = GraphicsUtils::GC.new(image)
        gc.draw_image(@icon, ICON_PADDING, ICON_PADDING)
        gc.dispose
      end

      def dirty!
        @img = nil
      end

      def activate
        @tab.activate
      end

      def active= boolean
        @active = boolean
        redraw
      end

      def title= (str)
        @title = str
        redraw
      end

      def redraw
        dirty!
        @label.image = label_image
      end

      def dispose
        @label.dispose
      end

      def show_close= boolean
        return if @show_close == boolean
        @show_close = boolean
        @show_close ? @label.add_mouse_track_listener(self) : @label.remove_mouse_track_listener(self)
      end

      def mouseUp(e)
        if show_close and close_icon.bounds.contains(e.x - ICON_PADDING, e.y - ICON_PADDING)
          @tab.parent.remove_item(@tab)
        else
          activate if e.button == 1
        end
      end

      def mouseEnter(e)
        @icon = close_icon
        redraw
      end

      def mouseExit(e)
        @icon = nil
        redraw
      end

      # Unused
      def mouseDown(e); end
      def mouseDoubleClick(e); end
      def mouseHover(e); end
    end
  end
end