require 'timeout'
require 'drb'

def drb
  DRbObject.new(nil, "druby://127.0.0.1:#{Redcar.drb_port}")
end

def tempfile(text)
  f = Tempfile.open("drb_testing")
  f << text
  f.close
  f.path
end

Given /^I open "([^"]*)" using the redcar command$/ do |path|
  drb_answer = drb.open_item_drb(File.expand_path(path))
  drb_answer.should == "ok"
end

Given /^I open "([^"]*)" using the redcar command with "-w"$/ do |path|
  DrbShelloutHelper.drb_system_thread = Thread.new(path) do
    drb_answer = drb.open_item_drb(File.expand_path(path), false, true)
  end
end

Given /^I pipe "([^"]*)" into redcar with "-w"$/ do |text|
  DrbShelloutHelper.drb_system_thread = Thread.new(text) do
    drb_answer = drb.open_item_drb(tempfile(text), true, true)
  end
end

Given /^I pipe "([^"]*)" into redcar$/ do |text|
  drb_answer = drb.open_item_drb(tempfile(text), true)
  drb_answer.should == "ok"
end

Then /^the redcar command should (not )?have returned$/ do |returned|
  (!!DrbShelloutHelper.drb_system_thread.status).should be !!returned # status is false for returned thread
end

