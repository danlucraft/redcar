When /^I prefer not to see files like "([^"]*)" in the find file dialog$/ do |pattern|

  ignored = filter_storage['ignore_files_that_match_these_regexes']
  ignored << /#{pattern}/
  filter_storage['ignore_file_patterns'] = true
  filter_storage['ignore_files_that_match_these_regexes'] = ignored
end

When /^I open the find file dialog$/ do
  Redcar::Project::FindFileCommand.new.run
end