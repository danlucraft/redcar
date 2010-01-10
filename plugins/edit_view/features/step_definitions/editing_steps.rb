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