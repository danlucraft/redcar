def outline_view
  dialog(Redcar::OutlineViewSWT::OutlineViewDialogSWT)
end

def outline_view_items
  outline_view.list.get_items.to_a
end

Then /^I open an outline view$/ do
  Redcar::OutlineView::OutlineViewDialog.new(Redcar.app.focussed_window.focussed_notebook_tab.document).open
end

Then /^there should be an outline view open$/ do
  outline_view.should_not be_nil
end

Then /^there should be no outline view open$/ do
  outline_view.should be_nil
end

When /^I set the outline filter to "(.*)"$/ do |text|
  outline_view.text.set_text(text)
end

When /^I select the outline view$/ do
  outline_view.controller.selected
end

When /^I wait (\d+) seconds$/ do |time|
  Cucumber::Ast::StepInvocation.wait_time = time.to_f
end

Then /^the outline view should have (no|\d+) entr(?:y|ies)$/ do |num|
  num = (num == "no" ? 0 : num.to_i)
  outline_view_items.length.should == num
end

Then /^I should see "(.*)" at (\d+)(?: with the "(.*)" icon )in the outline view$/ do |text, pos, icon|
  pos = pos.to_i
  outline_view_items[pos].text.should == text
  icon = Redcar::OutlineViewSWT::ICONS[icon.to_sym]
  item = outline_view_items[pos]
  item.get_image.should == icon
end

