
Given /^I have open a file$/ do
  Redcar::Project::OpenFileCommand.new.run
end

Given /^I will open a large file from the "([^"]*)" dialog$/ do |arg1|
  Given %Q|I will choose "plugins/project/spec/fixtures/winter.txt" from the "open_file" dialog|
  Redcar::Project::Manager.file_size_limit = 1
end

When /^I open a file$/ do
  Redcar::Project::OpenFileCommand.new.run
end

Given /^I have opened "([^\"]*)"$/ do |arg1|
  Redcar::Project::OpenFileCommand.new(File.expand_path(arg1)).run
end

Given /^I have opened "([^\"]*)" from the project$/ do |arg1|
  project = Redcar::Project::Manager.focussed_project
  Redcar::Project::OpenFileCommand.new(project.path + "/" + arg1).run
end

When /^I save the tab$/ do
  Redcar::Project::SaveFileCommand.new.run
end

When /^I touch the file "([^\"]*)"$/ do |fn|
  FileUtils.touch(fn)
  add_test_file(fn)
end

When /^I put "([^\"]*)" into the file "([^\"]*)"$/ do |contents, path|
  File.open(path, "w") {|fout| fout.print contents }
end

When /^I save the tab as$/ do
  Redcar::Project::SaveFileAsCommand.new.run
end

Then /^the file "([^"]*)" should be deletable$/ do |path|
  File.delete path
  raise if File.exist? path
end

Then /^the file "([^\"]*)" should contain "([^\"]*)"$/ do |arg1, arg2|
  File.read(arg1).should == arg2
end

When /^I put a lot of lines into the file "([^\"]*)"$/ do |file|
  File.open(file, "w") do |f|
    200.times { |i| f.puts(i * 20) }
  end
end

def add_test_file(fn)
  (@test_files ||= []) << File.expand_path(fn)
end

def remove_test_files
  (@test_files||[]).each { |fn| FileUtils.rm_f(fn) }
end

After do
  remove_test_files
end
