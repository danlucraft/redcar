
module Gutkumber
  def self.find_gtk_window(title)
    Gtk::Window.toplevels.detect do |window| 
      window.title =~ Regexp.new(Regexp.escape(title))
    end
  end
  
  def self.window_buttons(window)
    buttons = window.child_widgets_with_class(Gtk::Button)
    buttons.map {|button| button.child_widgets_with_class(Gtk::Label).map{|la| la.text}.join(" ") }
  end
  
  def self.find_button(window, button_label)
    buttons = window.child_widgets_with_class(Gtk::Button)
    buttons.each do |button|
      label = button.child_widgets_with_class(Gtk::Label).map{|la| la.text}.join(" ")
      return button if label =~ Regexp.new(Regexp.escape(button_label))
    end
    nil
  end
end

When /I click the button #{FeaturesHelper::STRING_RE} in the dialog #{FeaturesHelper::STRING_RE}/ do |button, dialog|
  button, dialog = parse_string(button), parse_string(dialog)
  dialog = Gutkumber.find_gtk_window(dialog)
  button = Gutkumber.find_button(dialog, button)
end

Then /I should see a dialog "([^"]+)" with buttons "([^"]+)"/ do |title, button_names| # "
  buttons = Gutkumber.window_buttons(Gutkumber.find_gtk_window(title))
  button_names.split(",").map(&:strip).each do |name|
    buttons.should include(name)
  end
end

