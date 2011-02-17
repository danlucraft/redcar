
When /^I open the incremental search speedbar$/ do
  Redcar::DocumentSearch::OpenIncrementalSearchSpeedbarCommand.new.run
end

When /^I open the find speedbar$/ do
  Redcar::DocumentSearch::OpenFindSpeedbarCommand.new.run
end

Then /^I should see the incremental search speedbar$/ do
  Then "the Redcar::DocumentSearch::IncrementalSearchSpeedbar speedbar should be open"
end

Then /^I should see the find speedbar$/ do
  Then "the Redcar::DocumentSearch::FindSpeedbar speedbar should be open"
end