When /^I trim the line$/ do
  Redcar::LineTools::TrimLineAfterCursorCommand.new.run
end

When /^I lower the text$/ do
  Redcar::LineTools::LowerTextCommand.new.run
end

When /^I raise the text$/ do
  Redcar::LineTools::RaiseTextCommand.new.run
end
