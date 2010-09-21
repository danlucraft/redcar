Given /^I will set "([^"]*)" as a parameter$/ do |params|
  Redcar.gui.dialog_adapter.add_input(params)
end

When /^I open the runnables tree$/ do
  Redcar::Runnables::ShowRunnables.new.run
end

When /^I change the command to "([^"]*)"$/ do |name|
  current = File.read(runnable_config)
  File.open(runnable_config, 'w') do |f|
    f.print current.gsub("An app", name)
  end
end

When /^I go back to the "([^"]*)" window$/ do |title|
  Redcar.app.windows.detect { |w| w.title == title }.focus
end

When /^I note the number of windows$/ do
  @windows = Redcar.app.windows.size
end

Then /^I should see (\d+) more windows?$/ do |window_count|
  Redcar.app.windows.size.should == (@windows + window_count.to_i)
end

When /^I append parameters to the "([^"]*)" node in the tree$/ do |node_text|
  mirror     = Redcar.app.focussed_window.treebook.focussed_tree.tree_mirror
  node       = find_node_with_text(mirror.top, node_text)
  Redcar::Runnables::AppendParamsAndRunCommand.new(node).run
end

#  controller = focussed_tree.tree_controller
#  model      = focussed_tree.controller.model
#  mirror     = focussed_tree.tree_mirror
#  node       = find_node_with_text(mirror.top, node_text)
#
#  node.should_not be_nil