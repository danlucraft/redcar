When /^I press predict$/ do
  Swt.sync_exec do
    Redcar::Macros::PredictCommand.new.run
  end
end

When /^I press alternate predict$/ do
  Swt.sync_exec do
    Redcar::Macros::AlternatePredictCommand.new.run
  end
end

