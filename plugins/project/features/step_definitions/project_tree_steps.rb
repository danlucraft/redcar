Then /^"([^\"]*)" should be selected in the project tree$/ do |filename|
  Redcar::Project::Manager.focussed_project.tree.selection.first.text == filename
end

When /^I prefer to not highlight the focussed tab$/ do
  Redcar::Project::Manager.reveal_files = false
end