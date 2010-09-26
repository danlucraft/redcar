When /^I press predict$/ do
  Redcar::Macros::PredictCommand.new.run
end

When /^I press alternate predict$/ do
  Redcar::Macros::AlternatePredictCommand.new.run
end

