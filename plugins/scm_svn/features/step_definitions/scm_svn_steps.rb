#TODO: find a way to test the http and svn protocols
When /^I checkout a local repository$/ do
  path = create_dir(working_copy)
  svn_module.load(path)
  svn_module.remote_init(svn_repository_url,path)
end

When /^I add "([^"]*)" to the index$/ do |file|
  svn_module.index_add(File.new(get_dir(working_copy) + "/#{file}"))
end

Then /^I should have a working copy$/ do
  svn_module.repository?(get_dir(working_copy)).should == true
end

When /^I create a wc file named "([^"]*)"$/ do |file|
  FileUtils.touch(get_dir(working_copy) + "/#{file}")
end

When /^I create a wc directory named "([^"]*)"$/ do |dir|
  FileUtils.mkdir_p get_dir(working_copy) + "/#{dir}"
end

Then /^there should be "([^"]*)" unindexed files and "([^"]*)" indexed files$/ do |ucount, count|
    svn_module.unindexed_changes.length.should == ucount.to_i
    svn_module.indexed_changes.length.should == count.to_i
end

When /^I commit my changes with message "([^"]*)"$/ do |message|
  svn_module.commit!(message)
end

Then /^if I checkout to a new working copy, it should have "([^"]*)" files$/ do |file_count|
  path = create_dir(working_copy_2)
  svn_module_2.load(path)
  svn_module_2.remote_init(svn_repository_url,path)
  (Dir.entries(path).size - 3).to_i.should == file_count.to_i #minus 3 for '.' and '..' and '.svn'
end

