
When /^I expand the tree row "([^\"]*)"$/ do |row|
  item = top_tree.items.detect {|item| item.getText == row }
  viewer = focussed_tree.controller.viewer
  node = viewer.getViewerRowFromItem(item).getElement
  viewer.expandToLevel(node, 1)
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

Then /^the tree width should be the default$/ do
  width = Redcar.app.focussed_window.treebook.controller.tab_folder.bounds.width
  default = Redcar::ApplicationSWT::Window::TREEBOOK_WIDTH + Redcar::ApplicationSWT::Window::SASH_WIDTH - 5
  raise "The tree width was #{width}, expected #{default}" unless width == default
end

When /^I activate the "([^"]*)" node in the tree$/ do |node_text|
  controller = focussed_tree.tree_controller
  model      = focussed_tree.controller.model
  mirror     = focussed_tree.tree_mirror
  node       = find_node_with_text(mirror.top, node_text)

  node.should_not be_nil
  
  controller.activated(model, node)
end