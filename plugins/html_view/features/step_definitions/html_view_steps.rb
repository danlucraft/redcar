Then /^the HTML tab (should say|says) "([^"]*)"$/ do |_, needle|
  limit = 5
  contents = nil
  started = false
  
  thread = Thread.new do
    started = true
    start = Time.now
    contents = get_browser_contents
    while !contents.match(needle) && Time.now - start < limit
      contents = get_browser_contents
      sleep 0.1
    end    
  end

  Redcar.gui.yield_until { started && !thread.alive? }
  contents.should match needle
end
