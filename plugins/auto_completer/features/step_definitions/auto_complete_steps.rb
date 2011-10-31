
When /I auto-complete/ do
  Swt.sync_exec do
    Redcar::AutoCompleter::AutoCompleteCommand.new.run
  end
end