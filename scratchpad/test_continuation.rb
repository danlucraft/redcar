
require 'gtk2'
require '../vendor/glitter'

win = Gtk::Window.new

win.set_size_request(400,300)

but = Gtk::Button.new("Foo")
but2 = Gtk::Button.new("Bar")

win.quit_on_destroy
view = Gtk::TextView.new
win.add(Gtk::HBox.new) do
  pack_start(but)
  pack_start(view)
end

but.signal_connect(:clicked) do
  p :foo
  view.buffer.insert(view.buffer.get_iter_at_offset(0), "asdf")
end

view.buffer.signal_connect(:insert_text) do
  p :bar
end

win.show_all

Gtk.main
