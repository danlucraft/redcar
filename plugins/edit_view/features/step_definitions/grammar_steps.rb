
When /^I switch the language to (.*)$/ do |language|
  puts "this should use menus rather than setting it directly"
  Swt.sync_exec do
    Redcar.app.focussed_window.focussed_notebook.focussed_tab.edit_view.grammar = language
  end
end

