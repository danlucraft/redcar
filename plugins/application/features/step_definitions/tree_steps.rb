
When /^I expand the tree row "([^\"]*)"$/ do |row|
  item = top_tree.items.detect {|item| item.getText == row }
  viewer = Redcar.app.focussed_window.treebook.trees.last.controller.viewer
  node = viewer.getViewerRowFromItem(item).getElement
  viewer.expandToLevel(node, 1)
end

Then /^I should (not )?see "([^\"]*)" in the tree$/ do |bool, rows|
  bool = !bool
  matcher = bool ? be_true : be_false
  rows = rows.split(",").map {|r| r.strip}
  rows.each do |row|
    on_top = top_tree.item_texts.include?(row)
    on_2 = top_tree.items.any? {|item| item.getItems.to_a.any? {|sub_item| sub_item.getText == row } }
    on_top or on_2
  end
end

Then /^the tree width should be the default$/ do
  width = Redcar.app.focussed_window.treebook.trees.last.controller.viewer.control.bounds.width
  default = Redcar::ApplicationSWT::Window::TREEBOOK_WIDTH + Redcar::ApplicationSWT::Window::SASH_WIDTH - 5
  raise "The tree width was #{width}, expected #{default}" unless width == default
end
