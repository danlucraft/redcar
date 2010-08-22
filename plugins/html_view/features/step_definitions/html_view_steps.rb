require 'ruby-debug'

Then /^the HTML tab should say "([^"]*)"$/ do |needle|
  limit = 5
  contents = nil
  
  @thread = Thread.new do
    start = Time.now
    contents = get_browser_contents
    while !contents.match(needle) && Time.now - start < limit
      contents = get_browser_contents
      sleep 0.1
    end    
  end

  Redcar.gui.yield_until { !@thread.alive? }
  contents.should match needle
end