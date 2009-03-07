
def make_event_button(window, x, y, button, type)
  case type
  when :press
    event_key = Gdk::EventButton.new(Gdk::Event::BUTTON_PRESS)
  when :press2
    event_key = Gdk::EventButton.new(Gdk::Event::BUTTON2_PRESS)
  when :press3
    event_key = Gdk::EventButton.new(Gdk::Event::BUTTON3_PRESS)
  when :release
    event_key = Gdk::EventButton.new(Gdk::Event::BUTTON_RELEASE)
  end
  event_key.x = x
  event_key.y = y
  event_key.button = button
  event_key.time = Gdk::Event::CURRENT_TIME
  event_key.window = window
  event_key
end

def right_click_on(widget)
  make_event_button(widget.window, 0, 0, 3, :press).put
  make_event_button(widget.window, 0, 0, 3, :release).put
end

When /^I right click on the (\w+)$/ do |tab_type| # 
  tab = only(Redcar.win.collect_tabs(Redcar.const_get(tab_type)))
  widget = tab.gtk_tab_widget
  right_click_on(widget)
end
