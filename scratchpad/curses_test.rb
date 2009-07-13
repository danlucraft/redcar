=begin
# Example ncurses program that should print all combinations of foreground
# color on background color but doesn't work.
# Reduce the font so you can make your terminal 256 characters wide for best view.
 
require 'rubygems'
require 'ncurses'
 
screen = Ncurses.initscr
Ncurses.noecho
Ncurses.cbreak
Ncurses.start_color
 
screen.addstr(Ncurses.COLORS.to_s)
screen.getch
 
Ncurses.curs_set 0
Ncurses.move 0, 0
Ncurses.clear
Ncurses.refresh
 
color_count = 0
256.times do |fg|
  256.times do |bg|
    Ncurses.init_pair(color_count, fg, bg)
    color_count += 1
  end
end
color_count.times do |i|
  screen.attrset(Ncurses.COLOR_PAIR(i))
  screen.addstr("#")
end
screen.getch
 
Ncurses.endwin
=end

require 'curses'

Curses::init_screen
Curses::nonl
Curses::raw
Curses::noecho
p Curses.can_change_color?
Curses.start_color
p :bazz
# screen.keypad(1)
p :qux
begin
  color_count = 0
  256.times do |fg|
    256.times do |bg|
      Curses.init_pair(color_count, fg, bg)
      color_count += 1
    end
  end
  color_count.times do |i|
    Curses.attrset(Curses.color_pair(i))
    Curses.addstr("#")
  end
  Curses.getch
  
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
