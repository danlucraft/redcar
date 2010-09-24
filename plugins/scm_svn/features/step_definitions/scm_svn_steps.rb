
When /^I commit my changes with message "([^"]*)"$/ do |message|
  svn_module.commit!(message)
end

When /^I ignore "([^"]*)"$/ do |file|
  svn_module.index_ignore(File.new(svn_module.path + "/#{file}"))
end

When /^I ignore "([^"]*)" files$/ do |extension|
  svn_module.index_ignore_all(extension,nil)
end

When /^I wc delete "([^"]*)"$/ do |file|
  path = svn_module.path + "/#{file}"
  svn_module.index_delete(Redcar::Scm::Subversion::Change.new(path,:normal,[],nil))
end

When /^I revert "([^"]*)"$/ do |file|
svn_module.index_revert(File.new(svn_module.path+"/#{file}"))
end

Then /^if I update my new working copy, it should have "([^"]*)" files$/ do |file_count|
  svn_module_2.pull!
  repo_file_count(svn_module_2.path).should == file_count.to_i
end