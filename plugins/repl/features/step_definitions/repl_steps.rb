When /^I open a "([^"]*)" repl$/ do |repl|
  Redcar.const_get(repl.camelize).const_get(repl.camelize + "OpenREPL").new.run
end
