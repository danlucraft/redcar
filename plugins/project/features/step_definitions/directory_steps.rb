
When /I open a directory/ do
  Redcar::Project::DirectoryOpenCommand.new.run
end

When /^I refresh the directory tree$/ do
  Redcar::Project.refresh_tree(Redcar.app.focussed_window)
end

When /^I move the myproject fixture away$/ do
  FileUtils.mv("plugins/project/spec/fixtures/myproject",
               "plugins/project/spec/fixtures/myproject.bak")
  @put_myproject_fixture_back = true
end