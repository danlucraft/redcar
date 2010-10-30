When /^I open a "([^"]*)" repl$/ do |repl|
  Redcar::REPL.const_get(repl.camelize + "OpenREPL").new.run
end
