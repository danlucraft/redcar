
When /I open a directory/ do
  Redcar::Project::DirectoryOpenCommand.new.run
end

When /I close the directory/ do
  Redcar::Project::DirectoryCloseCommand.new.run
end

When /^I refresh the directory tree$/ do
  Redcar::Project::Manager.focussed_project.refresh
end

When /^I rename "([^"]*)" to "([^"]*)" in the project tree$/ do |node_text, new_name|
  tree       = Redcar.app.focussed_window.treebook.focussed_tree
  controller = tree.tree_controller
  mirror     = tree.tree_mirror
  node       = find_node_with_text(mirror.top, node_text)
  controller.rename(tree,node)
end

When /^I move the myproject fixture away$/ do
  FileUtils.mv("plugins/project/spec/fixtures/myproject",
               "plugins/project/spec/fixtures/myproject.bak")
  @put_myproject_fixture_back = true
end

When /^I open a "([^"]*)" as a subproject of the current directory$/ do |arg1|
  path = Redcar::Project::Manager.focussed_project.path
  Redcar::Project::Manager.open_subproject(path,path + arg1)
end

Then /^"([^"]*)" in the project configuration files$/ do |arg1|
  project = Redcar::Project::Manager.focussed_project
  project.config_files(arg1).each do |file|
    File.exist?(file).should == true
  end
end

When /^"([^"]*)" goes missing$/ do |arg1|
  FileUtils.rm(arg1)
end

Then /^the focussed tab should have an "([^"]*)" icon$/ do |arg1|
  tab = Redcar.app.focussed_window.focussed_notebook_tab
  tab.icon.should == File.expand_path(File.join(Redcar::ICONS_DIRECTORY, "#{arg1}.png"))
end