#!/usr/bin/env ruby

class ColorDemo

ColorString = '##'
ColorMode = {'fg' => '38', 'bg' => '48'}

def show_welcome
  puts <<-END
  +—————————————————————————-+
  | This program shows 256-color support in xterm-compliant terminals. You may |
  | notice some flickering while the color codes are mapped in your terminal. |
  | Please resize your terminal to at least the width of this box. Try this: |
  | xterm -fg beige -bg midnightblue -fa "antialias=true:rgba=0:pixelsize=18" |
  +————-+————————————————————–+
  | Color Range | Description |
  +————-+————————————————————–+
  | 000 – 015 | Standard ANSI colors, but with more pleasing shades |
  | 016 – 231 | 6×6x6 color cube |
  | 232 – 255 | Greyscale ramp, with black and white intentionally omitted |
  +————-+————————————————————–|
  | Translation: 256colors.rb by Daniel Butler 2005-10-30 |
  | Original: 256colors2.pl by Todd Larason v1.1 1999-07-11 |
  +—————————————————————————-+
  END
end

def clear_screen
system("clear")
end

def loop_color_cube(mode = nil)
(0...6).each do |red|
(0...6).each do |green|
(0...6).each do |blue|
yield red, green, blue
end
print nocolor(" ") if mode == :cube
end
print "\n" if mode == :cube
end
end

def setup_color_cube_color
# Colors 16-231 are a 6×6x6 color cube
loop_color_cube do |red, green, blue|
printf("\x1b]4;%d;rgb:%2.2x/%2.2x/%2.2x\x1b\\",
16 + (red * 36) + (green * 6) + blue,
(red * 42.5).to_i,
(green * 42.5).to_i,
(blue * 42.5).to_i)
end
end

def setup_color_cube_gray
# Colors 232-255 are a grayscale ramp, intentionally
# leaving out black and white
(0...24).each do |gray|
level = (gray * 10) + 8
printf("\x1b]4;%d;rgb:%2.2x/%2.2x/%2.2x\x1b\\",
232 + gray, level, level, level);
end
end

def colorize(color, text, mode)
"\x1b[#{ColorMode[mode]};5;#{color}m#{text}"
end

def nocolor(text)
"\x1b[0m#{text}"
end

def display_system_colors(mode)
puts "System colors (#{mode}):"
(0...16).each do |color|
print colorize(color, ColorString, mode)
print nocolor("\n") if [7, 15].include? color
end
end

def display_color_cube(mode)
puts "Color cube, 6×6x6 (#{mode}):"
loop_color_cube(:cube) do |red, green, blue|
print colorize(16 + (red * 36) +
(green * 6) + blue, ColorString, mode)
end
end

def display_grayscale_ramp(mode)
puts "Grayscale ramp (#{mode}):"
(232...256).each do |color|
print colorize(color, ColorString, mode)
end
print nocolor("\n")
end

def go
clear_screen
show_welcome
setup_color_cube_color
setup_color_cube_gray
['fg', 'bg'].each do |mode|
display_system_colors(mode)
display_color_cube(mode)
display_grayscale_ramp(mode)
end
end
end

demo = ColorDemo.new
demo.go