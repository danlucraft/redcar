
require 'gtk2'
require 'ruby_thing'

win = Gtk::Window.new
Thing.new.get_gobj(win)
win.show
Gtk.main
