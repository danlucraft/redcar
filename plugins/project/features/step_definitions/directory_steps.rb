
When /I open a directory/ do
  Redcar::Project::DirectoryOpenCommand.new.run
end

When /^I refresh the directory tree$/ do
  Redcar::Project.refresh_tree(Redcar.app.focussed_window)
end
