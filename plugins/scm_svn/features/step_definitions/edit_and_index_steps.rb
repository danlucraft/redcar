When /^I add "([^"]*)" to the index$/ do |file|
  svn_module.index_add(File.new(get_dir(working_copy) + "/#{file}"))
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

When /^I replace "([^"]*)" contents with "([^"]*)"$/ do |file,text|
  File.open(get_dir(working_copy) + "/#{file}", 'w') do |f|
    f.rewind
    f.truncate(0)
    f.puts text
  end
end

Then /^the contents of wc file "([^"]*)" should be "([^"]*)"$/ do |file,text|
  File.read(get_dir(working_copy) + "/#{file}").rstrip.should == text
end