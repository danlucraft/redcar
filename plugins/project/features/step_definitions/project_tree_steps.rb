Then /^"([^\"]*)" should be selected in the project tree$/ do |filename|
  Swt.sync_exec do
    Redcar::Project::Manager.focussed_project.tree.selection.first.text == filename
  end
end

When /^I prefer to not highlight the focussed tab$/ do
  Swt.sync_exec do
    Redcar::Project::Manager.reveal_files = false
  end
end