
=begin
# Example nCurses program that should print all combinations of foreground
# color on background color but doesn't work.
# Reduce the font so you can make your terminal 256 characters wide for best view.
 
require 'rubygems'
require 'nCurses'
 
screen = NCurses.initscr
NCurses.noecho
NCurses.cbreak
NCurses.start_color
 
screen.addstr(NCurses.COLORS.to_s)
screen.addstr("  ")
screen.addstr(NCurses.COLOR_PAIRS.to_s)
screen.getch
 
NCurses.curs_set 0
NCurses.move 0, 0
NCurses.clear
NCurses.refresh
 
color_count = 0
256.times do |fg|
  256.times do |bg|
    NCurses.init_pair(color_count, fg, bg)
    color_count += 1
  end
end
256.times do |i|
  NCurses.clear
  256.times do |j|
    screen.attrset(NCurses.COLOR_PAIR(i*256 + j))
    screen.addstr("#")
  end
  screen.getch
end
screen.getch
 
NCurses.endwin
=end

require 'curses'

scr = Curses::init_screen
Curses::nonl
Curses::raw
Curses::noecho
p Curses.can_change_color?
Curses.start_color
scr.keypad(1)
p :bazz
# screen.keypad(1)
p :qux

LETTERS = "abcdefghijklmnopqrstuvwxyz"

def decode_key(ch, alt)
  base = case ch
          when 1..26
            "Ctrl+#{LETTERS[ch-1]}"
          when 65..(65+26)
            "Shift+" + LETTERS[ch-65].upcase
          when 97..(97+26)
            LETTERS[ch-97]
          when Curses::KEY_DOWN
            "down"
          when Curses::KEY_UP
            "up"
          when Curses::KEY_LEFT
            "left"
          when Curses::KEY_RIGHT
            "right"
          end
  if alt
    "Alt+" + base
  else
    base
  end
end

begin  # 
  # color_count = 0
  # 256.times do |fg|
  #   Curses.init_pair(color_count, fg, 0)
  #   color_count += 1
  # end
  # 100.times do |fg|
  #   Curses.init_pair(color_count, fg, 200)
  #   color_count += 1
  # end
  # 256.times do |fg|
  #   Curses.init_pair(color_count, 1, fg)
  #   color_count += 1
  # end  # 
    # (1*color_count).times do |i|
    #   Curses.attrset(Curses.color_pair(i))
    #   r = Curses.color_content(i)
    #   Curses.addstr(r.inspect)
    # end
  r = Curses.getch
  while r.ord != Curses::KEY_CTRL_F
    alt = false
    if r.ord == 27
      r = Curses.getch
      alt = true
    end
    Curses.addstr(r.inspect)
    Curses.addstr(" ")
    Curses.addstr(r.ord.inspect)
    if res = decode_key(r.ord, alt)
      Curses.addstr(" ")
      Curses.addstr(res)
    end
    Curses.addstr("\n")
    r = Curses.getch
  end
    # 
    # color_count = 0
    # 256.times do |fg|
    #   Curses.init_pair(color_count, fg, 256-fg)
    #   color_count += 1
    # end
    # # color_count = 0
    # # 120.times do |fg|
    # #   Curses.init_pair(color_count, fg, 0)
    # #   color_count += 1
    # # end
    # # 120.times do |fg|
    # #   Curses.init_pair(color_count, fg, 80)
    # #   color_count += 1
    # # end
    #   (1s*color_count).times do |i|
    #     Curses.attrset(Curses.color_pair(i))
    #     Curses.addstr("#")
    #   end
    # Curses.getch
rescue Object => e
  Curses.close_screen
  puts e.message
  puts e.backtrace
ensure
  Curses.nocbreak
  # Curses.keypad(0)
  Curses.echo
end
