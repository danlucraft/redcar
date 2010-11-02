require 'timeout'
require 'drb'

Given /^I open "([^"]*)" using the redcar command$/ do |path|
  drb = DRbObject.new(nil, "druby://127.0.0.1:#{Redcar::DRB_PORT}")
  drb_answer = drb.open_item_drb(path, false)
  drb_answer.should == "ok"
end

Given /^I open "([^"]*)" using the redcar command with "-w"$/ do |path|
  drb = DRbObject.new(nil, "druby://127.0.0.1:#{Redcar::DRB_PORT}")
  DrbShelloutHelper.drb_system_thread = Thread.new(path) do
    drb_answer = drb.open_file_and_wait(path, false)
  end
end

Given /^I pipe "([^"]*)" into redcar with "-w"$/ do |text|
  path = ""
  Tempfile.open("drb_testing") do |f|
    f << text
    path = f.path
  end
  drb = DRbObject.new(nil, "druby://127.0.0.1:#{Redcar::DRB_PORT}")
  DrbShelloutHelper.drb_system_thread = Thread.new(text) do
    drb_answer = drb.open_file_and_wait(path, true)
  end
end

Given /^I pipe "([^"]*)" into redcar$/ do |text|
  path = ""
  Tempfile.open("drb_testing") do |f|
    f << text
    path = f.path
  end
  drb = DRbObject.new(nil, "druby://127.0.0.1:#{Redcar::DRB_PORT}")
  drb_answer = drb.open_item_drb(path, true)
  drb_answer.should == "ok"
end

Then /^the redcar command should (not )?have returned$/ do |returned|
  (!!DrbShelloutHelper.drb_system_thread.status).should be !!returned # status is false for returned thread
end

