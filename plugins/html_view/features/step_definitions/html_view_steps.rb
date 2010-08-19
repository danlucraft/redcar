require 'ruby-debug'

Then /^the HTML tab should say "([^"]*)"$/ do |needle|
  limit = 5
  @thread = Thread.new(limit) do |limit|
    start = Time.now
    
    contents = get_browser_contents
    now = start
    while !(match = contents.match(needle)) && now - start < limit
      contents = get_browser_contents
      sleep 0.1
      now = Time.now
      puts "Looping at #{now}"
    end
    
    puts "Unable to find #{needle} in #{limit} seconds in contents:\n #{contents}" if !match
    puts "Found '#{needle}' in the browser" if match
    
    Redcar.gui.stop
  end

  Redcar.gui.stop
  Redcar.gui.start
  puts "cuke continued... sort of."
end