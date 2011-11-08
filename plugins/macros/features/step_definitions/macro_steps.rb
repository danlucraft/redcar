When /I start recording a macro/ do
  Swt.sync_exec do
    Redcar::Macros::StartStopRecordingCommand.new.run(:env => {:tab => implicit_edit_tab})
  end
end

When /I stop recording a macro/ do
  Swt.sync_exec do
    Redcar::Macros::StartStopRecordingCommand.new.run(:env => {:tab => implicit_edit_tab})
  end
end

When /I run the last recorded macro/ do
  Swt.sync_exec do
    Redcar::Macros::RunLastCommand.new.run(:env => {:edit_view => implicit_edit_view})
  end
end
