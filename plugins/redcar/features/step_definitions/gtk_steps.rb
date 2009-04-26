
module Gutkumber
  TICK_SIZE = ENV["GUTKUMBER_TICK_SIZE"] || 0.3
  
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
  
  def self.wait_tick
    Gtk.main_iteration while Gtk.events_pending?
    sleep TICK_SIZE
  end
end

When /I click the button #{FeaturesHelper::STRING_RE} in the dialog #{FeaturesHelper::STRING_RE}/ do |button, dialog|
  button, dialog = parse_string(button), parse_string(dialog)
  dialog = Gutkumber.find_gtk_window(dialog)
  button = Gutkumber.find_button(dialog, button)
 
  dialog.response(dialog.get_response(button))
  # sadly necessary for some reason. Please tell me why!
  Gutkumber.wait_tick
end

When /^I save as #{FeaturesHelper::STRING_RE}$/ do |filename|
  filename = parse_string(filename)
  dialog = Gutkumber.find_gtk_window("Save As")
end

When /^I set the #{FeaturesHelper::STRING_RE} dialog's filename to #{FeaturesHelper::STRING_RE}$/ do |dialog, filename|
  dialog, filename = parse_string(dialog), parse_string(filename)
  dialog = Gutkumber.find_gtk_window(dialog)
  table = dialog.child_widgets_with_class(Gtk::Table).first
  mystery_gtk = table.children[2]
  dialog.filename = filename
  mystery_gtk.text = filename.split("/").last
end

Then /I should see a dialog "([^"]+)" with buttons "([^"]+)"/ do |title, button_names| # "
  dialog = Gutkumber.find_gtk_window(title)
  raise "couldn't find dialog #{title.inspect}" unless dialog
  buttons = Gutkumber.window_buttons(dialog)
  button_names.split(",").map(&:strip).each do |name|
    buttons.should include(name)
  end
end

Then /there should be no dialog called "([^"]+)"/ do |title|
  Gutkumber.find_gtk_window(title).should be_nil
end

