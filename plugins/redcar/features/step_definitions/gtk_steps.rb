
module Gutkumber
  def self.find_gtk_window(title)
    Gtk::Window.toplevels.detect {|window| window.title == title}
  end
  
  def self.window_buttons(window)
    buttons = window.child_widgets_with_class(Gtk::Button)
    buttons.map {|button| button.label}
  end
  
end	

Then /I should see a dialog "([^"]+)" with buttons "([^"]+)"(?: and "([^"]+)")?/ do |title, b1, b2| # "
  p(w=Gutkumber.find_gtk_window(title))
  p Gutkumber.window_buttons(w)
end
