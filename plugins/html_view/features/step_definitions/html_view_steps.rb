require 'ruby-debug'

Then /^the HTML tab should say "([^"]*)"$/ do |content| 
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