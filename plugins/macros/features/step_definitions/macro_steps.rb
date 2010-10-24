When /I start recording a macro/ do
  Redcar::Macros::StartStopRecordingCommand.new.run
end

When /I stop recording a macro/ do
  Redcar::Macros::StartStopRecordingCommand.new.run
end

When /I run the last recorded macro/ do
  Redcar::Macros::RunLastCommand.new.run
end
