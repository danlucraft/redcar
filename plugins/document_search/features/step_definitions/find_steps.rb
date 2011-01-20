When /^I open the find( and replace)? speedbar$/ do |replace|
  if replace
    Redcar::DocumentSearch::OpenFindAndReplaceSpeedbarCommand.new.run
  else
    Redcar::DocumentSearch::OpenFindSpeedbarCommand.new.run
  end
end

Then /^I should see the find( and replace)? speedbar$/ do |replace|
  if replace
    Then "the Redcar::DocumentSearch::FindAndReplaceSpeedbar speedbar should be open"
  else
    Then "the Redcar::DocumentSearch::FindSpeedbar speedbar should be open"
  end
end