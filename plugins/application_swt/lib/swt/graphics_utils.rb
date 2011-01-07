module Swt
  class GraphicsUtils
    import org.eclipse.swt.SWT
    import org.eclipse.swt.widgets.Display
    import org.eclipse.swt.graphics.FontMetrics
    import org.eclipse.swt.graphics.GC
    import org.eclipse.swt.graphics.Image
    import org.eclipse.swt.graphics.ImageData
    import org.eclipse.swt.graphics.Point
    import org.eclipse.swt.graphics.Rectangle

    ##
    # Draws text vertically (rotates plus or minus 90 degrees). Uses the current
    # font, color, and background.
    # <dl>
    # <dt><b>Styles: </b></dt>
    # <dd>UP, DOWN</dd>
    # </dl>
    #
    # @param string the text to draw
    # @param x the x coordinate of the top left corner of the drawing rectangle
    # @param y the y coordinate of the top left corner of the drawing rectangle
    # @param gc the GC on which to draw the text
    # @param style the style (SWT.UP or SWT.DOWN)
    #          <p>
    #          Note: Only one of the style UP or DOWN may be specified.
    #          </p>
    #
    def self.draw_vertical_text(string, x, y, gc, style)
      display = Display.current

      fm = gc.font_metrics
      pt = gc.text_extent(string)

      string_image = Image.new(display, pt.x, pt.y)
      string_gc = GC.new(string_image)

      string_gc.foreground = gc.foreground
      string_gc.background = gc.background
      string_gc.font = gc.font
      string_gc.draw_text(string, 0, 0)

      draw_vertical_image(string_image, x, y, gc, style)

      string_gc.dispose
      string_image.dispose
    end

    ##
    # Draws an image vertically (rotates plus or minus 90 degrees)
    # <dl>
    # <dt><b>Styles: </b></dt>
    # <dd>UP, DOWN</dd>
    # </dl>
    #
    # @param image the image to draw
    # @param x the x coordinate of the top left corner of the drawing rectangle
    # @param y the y coordinate of the top left corner of the drawing rectangle
    # @param gc the GC on which to draw the image
    # @param style the style (SWT.UP or SWT.DOWN)
    #          <p>
    #          Note: Only one of the style UP or DOWN may be specified.
    #          </p>
    #
    def self.draw_vertical_image(image, x, y, gc, style)
      display = Display.current

      sd = image.image_data
      dd = ImageData.new(sd.height, sd.width, sd.depth, sd.palette)
      up = (style == SWT::UP)

      # Transform all pixels
      sd.width.times do |sx|
        sd.height.times do |sy|
          dx = up ? sy : sd.height - sy - 1
          dy = up ? sd.width - sx - 1 : sx
          dd.set_pixel(dx, dy, sd.get_pixel(sx, sy))
        end
      end

      vertical = Image.new(display, dd)
      gc.draw_image(vertical, x, y)
      vertical.dispose
    end

    ##
    # Creates an image containing the specified text, rotated either plus or minus
    # 90 degrees.
    # <dl>
    # <dt><b>Styles: </b></dt>
    # <dd>UP, DOWN</dd>
    # </dl>
    #
    # @param text the text to rotate
    # @param font the font to use
    # @param foreground the color or pattern for the text
    # @param background the background color or pattern
    # @param style direction to rotate (up or down)
    # @param optional options hash for padding
    # @return Image
    #         <p>
    #         Note: Only one of the style UP or DOWN may be specified.
    #         </p>
    #
    def self.create_rotated_text(text, font, foreground, background, style, options = {})
      options = {:padding_x => 16, :padding_y => 4}.merge(options)

      display = Display.current

      gc = GC.new(display)
      gc.font = font

      fm = gc.font_metrics
      pt = gc.text_extent(text)
      extent = Rectangle.new(0, 0, pt.x + options[:padding_x], pt.y + options[:padding_y])
      gc.dispose

      string_image = Image.new(display, extent.width, extent.height)

      gc = GC.new(string_image)

      gc.font = font
      gc.foreground = foreground
      gc.background = background

      # Do customization
      yield(gc, extent) if block_given?

      gc.draw_text(text, options[:padding_x] / 2, options[:padding_y] / 2, true)

      image = create_rotated_image(string_image, style)
      gc.dispose
      string_image.dispose
      return image
    end

    ##
    # Creates a rotated image (plus or minus 90 degrees)
    # <dl>
    # <dt><b>Styles: </b></dt>
    # <dd>UP, DOWN</dd>
    # </dl>
    #
    # @param image the image to rotate
    # @param style direction to rotate (up or down)
    # @return Image
    #         <p>
    #         Note: Only one of the style UP or DOWN may be specified.
    #         </p>
    #
    def self.create_rotated_image(image, style)
      display = Display.current

      sd = image.image_data
      dd = ImageData.new(sd.height, sd.width, sd.depth, sd.palette)

      up = (style == SWT::UP)

      sd.width.times do |sx|
        sd.height.times do |sy|
          dx = up ? sy : sd.height - sy - 1
          dy = up ? sd.width - sx - 1 : sx
          dd.set_pixel(dx, dy, sd.get_pixel(sx, sy))
        end
      end

      return Image.new(display, dd)
    end

    def self.pixel_location_at_offset(offset)
      edit_view = Redcar::EditView.focussed_tab_edit_view
      if edit_view
        text_widget = edit_view.controller.mate_text.viewer.get_text_widget
        location    = text_widget.get_location_at_offset(offset)
        x, y = location.x, location.y
        widget_offset = text_widget.to_display(0,0)
        x += widget_offset.x
        y += widget_offset.y
        [x,y]
      end
    end

    def self.below_pixel_location_at_offset(offset)
      x, y = GraphicsUtils.pixel_location_at_offset(offset)
      if x and y
        edit_view = Redcar::EditView.focussed_tab_edit_view
        text_widget = edit_view.controller.mate_text.viewer.get_text_widget
        y += text_widget.get_line_height
        [x, y]
      end
    end
  end
end