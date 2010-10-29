
When /^I expand the tree row "([^\"]*)"$/ do |row|
  item = visible_tree_items(top_tree).detect {|item| item.getText == row }
  viewer = focussed_tree.controller.viewer
  node = viewer.getViewerRowFromItem(item).getElement
  viewer.expandToLevel(node, 1)
end

When /^I toggle tree visibility$/ do
  Redcar::Top::ToggleTreesCommand.new.run
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