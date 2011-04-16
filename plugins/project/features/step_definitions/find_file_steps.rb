When /^I prefer not to see files like "([^"]*)" in the find file dialog$/ do |pattern|
  Redcar::Project::FileList.add_hide_file_pattern(/#{pattern}/)
end

When /^I open the find file dialog$/ do
  Redcar::Project::FindFileCommand.new.run
end