
def make_event_button(window, x, y, button, type)
  case type
  when :press
    event_button = Gdk::EventButton.new(Gdk::Event::BUTTON_PRESS)
  when :press2
    event_button = Gdk::EventButton.new(Gdk::Event::BUTTON2_PRESS)
  when :press3
    event_button = Gdk::EventButton.new(Gdk::Event::BUTTON3_PRESS)
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

def right_click_on(widget)
  make_event_button(widget.window, 0, 0, 3, :press).put
  make_event_button(widget.window, 0, 0, 3, :release).put
end

def left_click_on(widget)
  make_event_button(widget.window, 0, 0, 1, :press).put
  make_event_button(widget.window, 0, 0, 1, :release).put
end

When /^I (right|left) click on the (\w+)$/ do |button, tab_type| # 
  tab = only(Redcar.win.collect_tabs(Redcar.const_get(tab_type)))
  widget = tab.gtk_tab_widget
  case button
  when "right"
    right_click_on(widget)
  when "left"
    left_click_on(widget)
  end
end
