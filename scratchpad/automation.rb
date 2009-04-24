
require 'gtk2'
require 'monitor'
require File.dirname(__FILE__) + "/../vendor/glitter"
require File.dirname(__FILE__) + "/../lib/gtk"

def make_event_button(window, x, y, button, type)
  case type
  when :press
    event_button = Gdk::EventButton.new(Gdk::Event::BUTTON_PRESS)
  when :release
    event_button = Gdk::EventButton.new(Gdk::Event::BUTTON_RELEASE)
  end
  event_button.x = x
  event_button.y = y
  event_button.button = button
  event_button.time = Gdk::Event::CURRENT_TIME
  event_button.window = window
  event_button
end
 
def left_click_on(widget)
  allocation = widget.allocation
  x = allocation.x + allocation.width/2
  y = allocation.y + allocation.height/2
  make_event_button(widget.window, x, y, 1, :press).put
  make_event_button(widget.window, x, y, 1, :release).put
end
 
button, label = nil, nil
win = Gtk::Window.new("bar") do
  vbox = Gtk::VBox.new
  add(vbox) do
    button = Gtk::Button.new("foo")
    label  = Gtk::Label.new("bar")
    pack_start(button)
    pack_start(label)
  end
end

button.signal_connect("clicked") do 
  p :clicked_on_button
end

button.signal_connect("button-press-event") do 
  p :button_press_event_button
end

label.signal_connect("button-press-event") do 
  p :button_press_event_label
end

win.show_all
p :a
Gtk.main_iteration while Gtk.events_pending?

left_click_on(button)

p :b
Gtk.main_iteration while Gtk.events_pending?

left_click_on(label)

p :c
Gtk.main_iteration while Gtk.events_pending?

sleep 3



