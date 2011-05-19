
Given /^the indentation rules are like Ruby's$/ do
  Redcar::AutoIndenter.test_rules = Redcar::AutoIndenter::Rules.new(/def/, /end/)
end

Given /^the indentation rules are like Java's$/ do
  Redcar::AutoIndenter.test_rules = Redcar::AutoIndenter::Rules.new(
    /^.*\{[^}"']*$|^\s*(public|private|protected):\s*$/, 
    /^(.*\*\/)?\s*\}([^}{"']*\{)?[;\s]*(\/\/.*|\/\*.*\*\/\s*)?$|^\s*(public|private|protected):\s*$/
  )
end

When /^I auto-indent/ do
  Redcar::AutoIndenter::IndentCommand.new.run
end
