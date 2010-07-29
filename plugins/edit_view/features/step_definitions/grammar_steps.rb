When /^I switch the language to (.*)$/ do |language|
  Redcar.app.focussed_window.focussed_notebook.focussed_tab.edit_view.grammar = language
end

