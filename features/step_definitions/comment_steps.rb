When /^I toggle block comment$/ do
  Redcar::Comment::ToggleSelectionCommentCommand.new.run
end

When /^I toggle comment lines$/ do
  Redcar::Comment::ToggleLineCommentCommand.new.run
end
Given /^insert single space after comment is (en|dis)abled$/ do |insert|
  if insert == "en"
    Redcar::Comment.storage['insert_single_space_for_zero_indentation'] = true
  elsif insert == "dis"
    Redcar::Comment.storage['insert_single_space_for_zero_indentation'] = false
  end
end