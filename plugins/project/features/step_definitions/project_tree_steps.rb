Then /^"([^\"]*)" should be selected in the project tree$/ do |filename|
  Redcar.app.focussed_window.treebook.focussed_tree.selection.first.text == filename
end