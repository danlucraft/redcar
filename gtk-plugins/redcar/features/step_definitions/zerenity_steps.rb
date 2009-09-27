
When /^I give the #{FeaturesHelper::STRING_RE} String dialog the input #{FeaturesHelper::STRING_RE}$/ do |dialog, string|
  dialog, string = parse_string(dialog), parse_string(string)
  p dialog
  dialog = Gutkumber.find_gtk_window(dialog)
  p dialog
  p dialog.title
end

