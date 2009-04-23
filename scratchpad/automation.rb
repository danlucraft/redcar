
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
  make_event_button(widget.window, 0, 0, 1, :press).put
  make_event_button(widget.window, 0, 0, 1, :release).put
end
 

win = Gtk::Window.new("bar")
button = Gtk::Button.new("foo")
button.signal_connect("clicked") do 
  p :clicked
end
button.signal_connect("button-press-event") do 
  p :button_press_event
end

win.add(button)
win.show_all

t = Time.now
Thread.new { 
  sleep 1
  button.clicked
  # left_click_on(button)
  sleep 1
  Gtk.main_quit
}

Gtk.main

