When /^I add "([^"]*)" to the index$/ do |files|
  files.split(",").each do |file|
    svn_module.index_add(File.new(get_dir(working_copy) + "/#{file}"))
  end
end

When /^I create a wc file named "([^"]*)"$/ do |files|
  files.split(",").each do |file|
    FileUtils.touch(get_dir(working_copy) + "/#{file}")
  end
end

When /^I create a wc directory named "([^"]*)"$/ do |dirs|
  dirs.split(",").each do |dir|
    FileUtils.mkdir_p get_dir(working_copy) + "/#{dir}"
  end
end

Then /^there should be "([^"]*)" unindexed files and "([^"]*)" indexed files$/ do |ucount, count|
    svn_module.unindexed_changes.length.should == ucount.to_i
    svn_module.indexed_changes.length.should   ==  count.to_i
end

When /^I replace "([^"]*)" contents(| in the new copy) with "([^"]*)"$/ do |file,repo,text|
  if repo == ""
    File.open(get_dir(working_copy) + "/#{file}", 'w') do |f|
      f.rewind
      f.truncate(0)
      f.puts text
    end
  else
    File.open(get_dir(working_copy_2) + "/#{file}", 'w') do |f|
      f.rewind
      f.truncate(0)
      f.puts text
    end
  end
end

Then /^the contents of wc file "([^"]*)"(| in the new copy) should be "([^"]*)"$/ do |file,repo,text|
  if repo == " in the new copy"
    File.read(get_dir(working_copy_2) + "/#{file}").rstrip.should == text
  else
    File.read(get_dir(working_copy) + "/#{file}").rstrip.should == text
  end
end

#Then /^the contents of wc file "([^"]*)" in the new copy should be "([^"]*)"$/ do |file,text|
#  File.read(get_dir(working_copy_2) + "/#{file}").rstrip.should == text
#end