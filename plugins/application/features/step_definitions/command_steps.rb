
When /^I run the command ([^\s]+)$/ do |command_name|
  command_class = eval(command_name)
  command = command_class.new
  if command.is_a?(Redcar::DocumentCommand)
    command.run(:env => {:edit_view => implicit_edit_view})
  else
    command.run
  end
end