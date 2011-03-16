When /^I prefer not to see files like "([^"]*)" in the find file dialog$/ do |pattern|
  ignored = shared_ignored_storage['ignored_file_patterns']
  ignored << /#{pattern}/
  filter_storage['ignore_file_patterns'] = true
  shared_ignored_storage['ignored_file_patterns'] = ignored
end

When /^I open the find file dialog$/ do
  Redcar::Project::FindFileCommand.new.run
end