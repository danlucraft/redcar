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
    svn_module.indexed_changes.length.should   ==  count.to_i
end

When /^I commit my changes with message "([^"]*)"$/ do |message|
  svn_module.commit!(message)
end

Then /^if I checkout to a new working copy, it should have "([^"]*)" files$/ do |file_count|
  path = create_dir(working_copy_2)
  svn_module_2.load(path)
  svn_module_2.remote_init(svn_repository_url,path)
  repo_file_count(svn_module_2.path).should == file_count.to_i
end

Then /^if I update my new working copy, it should have "([^"]*)" files$/ do |file_count|
  svn_module_2.pull!
  repo_file_count(svn_module_2.path).should == file_count.to_i
end

When /^I ignore "([^"]*)"$/ do |file|
  svn_module.index_ignore(File.new(svn_module.path + "/#{file}"))
end

When /^I wc delete "([^"]*)"$/ do |file|
  path = svn_module.path + "/#{file}"
  svn_module.index_delete(Redcar::Scm::Subversion::Change.new(path,:normal,[],nil))
end

When /^I ignore "([^"]*)" files$/ do |extension|
  svn_module.index_ignore_all(extension,nil)
end

When /^I revert "([^"]*)"$/ do |file|
  svn_module.index_revert(File.new(svn_module.path+"/#{file}"))
  data = ""
  f = File.open(svn_module.path+"/#{file}", "r")
  f.each_line {|line| puts line}
end