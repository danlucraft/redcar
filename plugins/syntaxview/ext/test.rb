
require 'gtk2'
require 'syntax_ext'

win = Gtk::Window.new
win.set_size_request(400, 400)
SyntaxExt.set_window_title(win, "Hello from C through Ruby!")
tv = Gtk::TextView.new
tv.show
win.add tv
win.show
win.signal_connect("destroy") { Gtk.main_quit }
tv.signal_connect("button_press_event") do
  SyntaxExt.make_red(tv.buffer)
end

Gtk.main
