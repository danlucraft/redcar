When /^I save the tab (\d+) times and wait (\d+) seconds each time$/ do |count,time|
  count = count.to_i
  time  = time.to_i
  (1..count).each do |i|
    begin
      When "I save the tab"
      When "I wait #{time} seconds"
    rescue => e
      add_exception(e)
    end
  end
end

Then /^the tab should not have thrown SWT concurrency exceptions$/ do
  exception_count.should == 0
end
