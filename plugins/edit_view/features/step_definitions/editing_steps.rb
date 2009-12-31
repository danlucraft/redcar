When /^I undo$/ do
  Redcar::Top::UndoCommand.new.run
end

When /^I redo$/ do
  Redcar::Top::RedoCommand.new.run
end
