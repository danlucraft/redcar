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
  
  # For now, just skip on windows. We can't get browser exec results
  # on current version of SWT and XulRunner. More info at:
  # https://bugs.eclipse.org/bugs/show_bug.cgi?id=259687
  contents.should match needle unless Redcar.platform == :windows
end