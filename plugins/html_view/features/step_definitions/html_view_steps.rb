require 'ruby-debug'

Then /^the HTML tab should say "([^"]*)"$/ do |needle|
  limit = 5
  @thread = Thread.new(limit, focussed_tab.html_view.controller) do |limit, c|
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
    Redcar.gui.stop
  end

  Redcar.gui.stop
  Redcar.gui.start
  puts "cuke continued"
  
  # Here is where I'd love to say browser.eval($(body).text()
  # But unfortunately the UI is already blocked at this point
  #@thread = Thread.new(focussed_tab) do |t|
  #  while true
  #    begin
  #      puts t.controller.browser.evaluate("$('body').text();")
  #    rescue org.eclipse.swt.SWTException => e
  #      p e
  #      p e.backtrace
  #    end
  #    sleep 0.5
  #  end
  #end
  #
  #while true
  #  sleep 0.5
  #end
end