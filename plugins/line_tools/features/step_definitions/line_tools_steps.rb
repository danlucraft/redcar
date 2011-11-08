When /^I kill the line$/ do
  Swt.sync_exec do
    Redcar::LineTools::KillLineCommand.new.run(:env => {:edit_view => implicit_edit_view})
  end
end

When /^I trim the line$/ do
  Swt.sync_exec do
    Redcar::LineTools::TrimLineAfterCursorCommand.new.run(:env => {:edit_view => implicit_edit_view})
  end
end

When /^I lower the text$/ do
  Swt.sync_exec do
    Redcar::LineTools::LowerTextCommand.new.run(:env => {:edit_view => implicit_edit_view})
  end
end

When /^I raise the text$/ do
  Swt.sync_exec do
    Redcar::LineTools::RaiseTextCommand.new.run(:env => {:edit_view => implicit_edit_view})
  end
end

When /^I replace the line$/ do
  Swt.sync_exec do
    Redcar::LineTools::ReplaceLineCommand.new.run(:env => {:edit_view => implicit_edit_view})
  end
end

When /^I clear the line$/ do
  Swt.sync_exec do
    Redcar::LineTools::ClearLineCommand.new.run(:env => {:edit_view => implicit_edit_view})
  end
end
