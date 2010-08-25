
Given /^the indentation rules are like Ruby's$/ do
  Redcar::AutoIndenter.test_rules = Redcar::AutoIndenter::Rules.new(/def/, /end/)
end

When /^I auto-indent/ do
  Redcar::AutoIndenter::IndentCommand.new.run
end
