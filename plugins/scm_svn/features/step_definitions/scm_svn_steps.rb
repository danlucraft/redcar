
When /^I commit my changes(| in the new copy) with message "([^"]*)"$/ do |repo,message|
  if repo == ""
    svn_module.commit!(message)
  else
    svn_module_2.commit!(message)
  end
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

Then /^if I update my(| new) working copy, it should have "([^"]*)" files$/ do |repo,file_count|
  if repo == " new"
    svn_module_2.pull!
    repo_file_count(svn_module_2.path).should == file_count.to_i
  else
    svn_module.pull!
    repo_file_count(svn_module.path).should == file_count.to_i
  end
end

Then /^there should be "([^"]*)" conflicted files(| in the new copy)$/ do |file_count,repo|
  if repo == ""
    mod = svn_module
  else
    mod = svn_module_2
  end
  changes = []
  mod.indexed_changes.map {|i| changes << i if i.status[0] == :unmerged}
  changes.length.should == file_count.to_i
end

When /^and I resolve "([^"]*)" conflicts(| in the new copy)$/ do |file,repo|
  if repo == ""
    mod = svn_module
  else
    mod = svn_module_2
  end
  changes = []
  mod.indexed_changes.map {|i| changes << i if i.status[0] == :unmerged}
  changes.each {|c| mod.resolve_conflict(c) if File.basename(c.path) == file}
end
