
When /^I run the command ([^\s]+)$/ do |command_name|
  command_class = eval(command_name)
  command_class.new.run
end