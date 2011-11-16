
Given /^I will open "([^"]*)" branch as a new project$/ do |branch_name|
  Swt.sync_exec do
    path = parse_branch_path(branch_name)
    if path
      Redcar.gui.dialog_adapter.set(:open_directory, path)
      @svn_module = Redcar::Scm::Subversion::Manager.new
      @svn_module.load(path)
    end
  end
end

When /^I switch to "([^"]*)" branch$/ do |branch_name|
  Swt.sync_exec do
    path = parse_branch_path(branch_name)
    Redcar.gui.dialog_adapter.set(:open_directory, path) if path
    svn_module.switch!(branch_name)
    svn_module.repository?(path).should == true
  end
end

When /^I merge the "([^"]*)" branch$/ do |branch_name|
  path = parse_branch_path(branch_name)
  svn_module.merge!(branch_name)
end

Then /^I should see "([^"]*)" in "([^"]*)" branch$/ do |files, branch_name|
  path = parse_branch_path(branch_name)
  files.split(",").each {|f|
    File.exist?(path + "/#{f}").should == true
  }
end
