#TODO: find a way to test the http and svn protocols
When /^I checkout "([^"]*)" in a local repository$/ do |subdirectory|
  path = create_dir(working_copy)
  path = path + "#{subdirectory}" if subdirectory
  File.mkdir_p(path) unless File.exist?(path)
  svn_module.load(path)
  svn_module.remote_init(svn_repository_url,path)
end

When /^I checkout a local repository$/ do
  path = create_dir(working_copy)
  svn_module.load(path)
  svn_module.remote_init(svn_repository_url,path)
end

Then /^I should have a working copy$/ do
  svn_module.repository?(get_dir(working_copy)).should == true
end

Then /^if I checkout to a new working copy, it should have "([^"]*)" files$/ do |file_count|
  path = create_dir(working_copy_2)
  svn_module_2.load(path)
  svn_module_2.remote_init(svn_repository_url,path)
  repo_file_count(svn_module_2.path).should == file_count.to_i
end