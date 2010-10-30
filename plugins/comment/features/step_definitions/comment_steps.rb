When /^I toggle block comment$/ do
  Redcar::Comment::ToggleSelectionCommentCommand.new.run
end

When /^I toggle comment lines$/ do
  Redcar::Comment::ToggleLineCommentCommand.new.run
end