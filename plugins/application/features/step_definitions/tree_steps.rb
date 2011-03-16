
When /^I expand the tree row "([^\"]*)"$/ do |row|
  item = visible_tree_items(top_tree).detect {|item| item.getText == row }
  viewer = focussed_tree.controller.viewer
  node = viewer.getViewerRowFromItem(item).getElement
  viewer.expandToLevel(node, 1)
end

When /^I toggle tree visibility$/ do
  Redcar::Application::ToggleTreesCommand.new.run
end

When "I close the tree" do
  Redcar::Application::CloseTreeCommand.new.run
end

When /^I switch (up|down) a tree$/ do |type|
  case type
  when "down"
    Redcar::Application::SwitchTreeDownCommand.new.run
  when "up"
    Redcar::Application::SwitchTreeUpCommand.new.run
  end
end

When "I click the close button" do
  vtabitem = focussed_window.treebook.controller.tab_folder.selection
  swtlabel = swt_label_for_item(vtabitem)

  # Make sure the close icon is showing
  FakeEvent.new(Swt::SWT::MouseEnter, swtlabel)

  # Fire the click event
  FakeEvent.new(Swt::SWT::MouseUp, swtlabel,
    :x => Swt::Widgets::VTabLabel::ICON_PADDING + 1,
    :y => Swt::Widgets::VTabLabel::ICON_PADDING + 1)
end

When /^I (?:(left|right)-)?click the (project|directory|"[^\"]*") tree tab$/ do |button, target|
  if target =~ /(project|directory)/
    path  = Redcar::Project::Manager.in_window(Redcar.app.focussed_window).path
    target = File.basename(path) + "/"
  end
  target.gsub!('"', '')
  vtabitem = focussed_window.treebook.controller.tab_folder.get_item(target)
  swtlabel = swt_label_for_item(vtabitem)

  button = (button == "right" ? 2 : 1)
  FakeEvent.new(Swt::SWT::MouseEnter, swtlabel)
  FakeEvent.new(Swt::SWT::MouseUp, swtlabel, :x => 1, :y => 1, :button => button)
end

Then /^I should (not )?see "([^\"]*)" in the tree$/ do |negate, rows|
  item_names = visible_tree_items(top_tree).map(&:get_text)
  rows.split(',').map(&:strip).each do |row|
    if negate
      item_names.should_not include row
    else
      item_names.should include row
    end
  end
end

Then /^there should (not )?be a tree titled "([^\"]*)"$/ do |negate,title|
  if negate
    tree_with_title(title).should == nil
  else
    tree_with_title(title).should_not == nil
  end
end

Then /^the focussed tree should be titled "([^\"]*)"$/ do |title|
  focussed_tree.title.should == title
end

Then /^the tree width should be (the default|\d+ pixels|the minimum size)$/ do |w|
  width = focussed_treebook_width
  if w == "the default"
    unless width == default_treebook_width
      raise "The tree width was #{width}, expected #{default_treebook_width}"
    end
  elsif w == "the minimum size"
    width.should == Redcar::ApplicationSWT::Window::MINIMUM_TREEBOOK_WIDTH
  else
    width.should == w.split(" ")[0].to_i
  end
end

When /^I activate the "([^"]*)" node in the tree$/ do |node_text|
  controller = focussed_tree.tree_controller
  model      = focussed_tree.controller.model
  mirror     = focussed_tree.tree_mirror
  node       = find_node_with_text(mirror.top, node_text)

  node.should_not be_nil

  controller.activated(model, node)
end

When /^I rename the "([^"]*)" node in the tree$/ do |node_text|
  controller = focussed_tree.tree_controller
  mirror     = focussed_tree.tree_mirror
  node       = find_node_with_text(mirror.top, node_text)

  node.should_not be_nil
  controller.single_rename(focussed_tree, node)
end