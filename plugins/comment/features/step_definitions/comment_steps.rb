When /^I toggle block comment$/ do
  Swt.sync_exec do
    Redcar::Comment::ToggleSelectionCommentCommand.new.run
  end
end

When /^I toggle comment lines$/ do
  Swt.sync_exec do
    Redcar::Comment::ToggleLineCommentCommand.new.run
  end
end