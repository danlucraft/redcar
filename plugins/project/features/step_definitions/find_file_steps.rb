When /^I prefer not to see files like "([^"]*)" in the find file dialog$/ do |pattern|
  Swt.sync_exec do
    Redcar::Project::FileList.add_hide_file_pattern(/#{pattern}/)
  end
end

When /^I open the find file dialog$/ do
  Swt.sync_exec do
    Redcar::Project::FindFileCommand.new.run
  end
end