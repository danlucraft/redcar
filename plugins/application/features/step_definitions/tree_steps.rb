
When /^I expand the tree row "([^\"]*)"$/ do |row|
  item = top_tree.items.detect {|item| item.getText == row }
  viewer = focussed_tree.controller.viewer
  node = viewer.getViewerRowFromItem(item).getElement
  viewer.expandToLevel(node, 1)
end

Then /^I should (not )?see "([^\"]*)" in the tree$/ do |negate, rows|
  items = visible_tree_items(top_tree)
  rows.split(',').map(&:strip).each do |row|
    if negate
      items.should_not include row
    else
      items.should include row
    end
  end
end

Then /^the tree width should be the default$/ do
  width = Redcar.app.focussed_window.treebook.trees.last.controller.viewer.control.bounds.width
  default = Redcar::ApplicationSWT::Window::TREEBOOK_WIDTH + Redcar::ApplicationSWT::Window::SASH_WIDTH - 5
  raise "The tree width was #{width}, expected #{default}" unless width == default
end
