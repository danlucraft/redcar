
class RRunnable
  include java.lang.Runnable
  
  def initialize(&block)
    @block = block
  end
  
  def run
    @block.call
  end
end

Then /^the window should have title "([^\"]*)"$/ do |title|
  actual_title = nil
  Redcar::ApplicationSWT.display.syncExec(RRunnable.new { actual_title = Redcar::ApplicationSWT.display.get_active_shell.get_text })
  actual_title.should == title
end