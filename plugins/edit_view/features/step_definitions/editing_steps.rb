When /^I undo$/ do
  Redcar::Top::UndoCommand.new.run
end

When /^I redo$/ do
  Redcar::Top::RedoCommand.new.run
end

When /^I select from (\d+) to (\d+)$/ do |start_offset, end_offset|
  doc = Redcar.app.focussed_window.focussed_notebook.focussed_tab.edit_view.document
  doc.set_selection_range((start_offset.to_i)..(end_offset.to_i))
end

When /^I copy text$/ do
  Redcar::Top::CopyCommand.new.run
end

When /^I cut text$/ do
  Redcar::Top::CutCommand.new.run
end

When /^I paste text$/ do
  Redcar::Top::PasteCommand.new.run
end

When /^I move the cursor to (\d+)$/ do |offset|
  doc = Redcar.app.focussed_window.focussed_notebook.focussed_tab.edit_view.document
  doc.cursor_offset = offset.to_i
end

Then /^the cursor should be at (\d+)$/ do |offset|
  doc = Redcar::EditView.focussed_tab_edit_view.document
  doc.cursor_offset.should == offset.to_i
end

When /^tabs are hard$/ do
  Redcar::EditView.focussed_tab_edit_view.soft_tabs = false
end

When /^tabs are soft, (\d+) spaces$/ do |int|
  Redcar::EditView.focussed_tab_edit_view.soft_tabs = true
  Redcar::EditView.focussed_tab_edit_view.tab_width = int.to_i
end

When /^I press the Tab key in the edit tab$/ do
  edit_view = Redcar::EditView.focussed_tab_edit_view
  edit_view.tab_pressed([])
end

When /^I press the Left key in the edit tab$/ do
  edit_view = Redcar::EditView.focussed_tab_edit_view
  edit_view.left_pressed([])
end

When /^I press the Right key in the edit tab$/ do
  edit_view = Redcar::EditView.focussed_tab_edit_view
  edit_view.right_pressed([])
end

When /^I press Shift\+Left key in the edit tab$/ do
  edit_view = Redcar::EditView.focussed_tab_edit_view
  edit_view.left_pressed(["Shift"])
end

When /^I press Shift\+Right key in the edit tab$/ do
  edit_view = Redcar::EditView.focussed_tab_edit_view
  edit_view.right_pressed(["Shift"])
end

Then /^the contents should be "([^\"]*)"$/ do |text|
  expected = text.gsub("\\t", "\t").gsub("\\n", "\n")
  doc = Redcar::EditView.focussed_edit_view_document
  actual = doc.to_s
  if expected.include?("<c>")
    actual = actual.insert(doc.cursor_offset, "<c>")
    seloff = doc.selection_offset
    if seloff > doc.cursor_offset
      seloff += 3
    end
    actual = actual.insert(seloff, "<s>")
  end
  actual.should == expected
end

Then /^the contents of the edit tab should be "([^\"]*)"$/ do |text|
  text = text.gsub("\\t", "\t").gsub("\\n", "\n")
  Redcar::EditView.focussed_edit_view_document.to_s.should == text
end


 