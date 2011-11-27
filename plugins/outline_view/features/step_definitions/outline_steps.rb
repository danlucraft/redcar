def outline_view
  dialog(Redcar::OutlineViewSWT::OutlineViewDialogSWT)
end

def outline_view_items
  Swt.sync_exec do
    outline_view.list.get_items.to_a
  end
end

Then /^I open an outline view$/ do
  Swt.sync_exec do
    Redcar::OutlineView::OutlineViewDialog.new(Redcar.app.focussed_window.focussed_notebook_tab.document).open
  end
end

Then /^there should be an outline view open$/ do
  Swt.sync_exec do
    outline_view.should_not be_nil
  end
end

Then /^there should be no outline view open$/ do
  Swt.sync_exec do
    outline_view.should be_nil
  end
end

When /^I set the outline filter to "(.*)"$/ do |text|
  Swt.sync_exec do
    outline_view.text.set_text(text)
  end
end

When /^I select the outline view$/ do
  Swt.sync_exec do
    outline_view.controller.selected
  end
end

Then /^the outline view should have (no|some|\d+) entr(?:y|ies)$/ do |num|
  Swt.sync_exec do
    if num == "some"
      outline_view_items.length.should > 0
    else
      num = (num == "no" ? 0 : num.to_i)
      outline_view_items.length.should == num
    end
  end
end

Then /^I should see "(.*)" at (\d+)(?: with the "(.*)" icon )in the outline view$/ do |text, pos, icon|
  Swt.sync_exec do
    pos = pos.to_i
    outline_view_items[pos].text.should == text
    icon = Redcar::OutlineViewSWT::ICONS[icon.to_sym]
    item = outline_view_items[pos]
    item.get_image.should == icon
  end
end

