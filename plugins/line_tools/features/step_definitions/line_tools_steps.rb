When /^I kill the line$/ do
  Redcar::LineTools::KillLineCommand.new.run(:env => {:edit_view => implicit_edit_view})
end

When /^I trim the line$/ do
  Redcar::LineTools::TrimLineAfterCursorCommand.new.run(:env => {:edit_view => implicit_edit_view})
end

When /^I lower the text$/ do
  Redcar::LineTools::LowerTextCommand.new.run(:env => {:edit_view => implicit_edit_view})
end

When /^I raise the text$/ do
  Redcar::LineTools::RaiseTextCommand.new.run(:env => {:edit_view => implicit_edit_view})
end

When /^I replace the line$/ do
  Redcar::LineTools::ReplaceLineCommand.new.run(:env => {:edit_view => implicit_edit_view})
end

When /^I clear the line$/ do
  Redcar::LineTools::ClearLineCommand.new.run(:env => {:edit_view => implicit_edit_view})
end
