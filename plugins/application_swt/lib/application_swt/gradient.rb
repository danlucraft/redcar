module Redcar
  class ApplicationSWT
    class Gradient
      # Expects a hash with gradient color locations from 1-100 as keys
      # and 6-character hex RGB strings as values
      def initialize(color_stops_or_solid_color)
        if color_stops_or_solid_color.is_a?(String)
          color_stops = {100 => color_stops_or_solid_color}
        else
          color_stops = color_stops_or_solid_color
        end
          
        raise ArgumentError, "Color stops must be in the range 0-100" if color_stops.any? { |position, color| (position < 0) || (position > 100) }
        @color_stops = color_stops
        make_start_and_end_stops_explicit!
      end
      
      def to_hash
        @color_stops
      end
  
      def swt_stops
        stops_with_implicit_zero = @color_stops.keys.sort - [0]
        stops_with_implicit_zero.to_java(:int)
      end
  
      def swt_colors
        hex_rgb_strings = @color_stops.sort.map { |position, color| color }
        colors = hex_rgb_strings.map do |hex_rgb_string|
          hex_string = case hex_rgb_string
            when /[0-9A-Fa-f]{6}/
              Regexp.last_match[0]
            when /[0-9A-Fa-f]{3}/
              Regexp.last_match[0].split('').map{ |hex_string| hex_string * 2 }.join('')
            else
              raise "Colors must be RGB hex strings"
          end
          
          color_components = hex_string.scan(/.{2}/)
          
          int_components = color_components.map { |component| component.to_i(16) }
        end
    
        swt_colors = colors.map { |color|  Swt::Graphics::Color.new(ApplicationSWT.display, *color[0...3])  }
        swt_colors.to_java(Swt::Graphics::Color)
      end
      
      private

      def make_start_and_end_stops_explicit!
        @color_stops[0] ||= @color_stops[@color_stops.keys.min]
        @color_stops[100] ||= @color_stops[@color_stops.keys.max]
      end
      
    end
  end
end