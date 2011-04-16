When /I start recording a macro/ do
  Redcar::Macros::StartStopRecordingCommand.new.run(:env => {:tab => implicit_edit_tab})
end

When /I stop recording a macro/ do
  Redcar::Macros::StartStopRecordingCommand.new.run(:env => {:tab => implicit_edit_tab})
end

When /I run the last recorded macro/ do
  Redcar::Macros::RunLastCommand.new.run(:env => {:edit_view => implicit_edit_view})
end
