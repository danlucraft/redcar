Given /^I have (not )?suppressed syntax checking message dialogs$/ do |negate|
  if negate
    Redcar::SyntaxCheck.storage['supress_message_dialogs'] = true
  else
    Redcar::SyntaxCheck.storage['supress_message_dialogs'] = false
  end
end

Given /^I excluded "(.*)" files from being checked for syntax errors$/ do |grammar|
  Redcar::SyntaxCheck.storage['excluded_grammars'] << grammar.downcase
end