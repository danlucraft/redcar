Then /^the HTML tab (should (not )?say|says) "([^"]*)"$/ do |_, negation, needle|
  limit = 5
  contents = nil
  started = false

  thread = Thread.new do
    started = true
    start = Time.now
    contents = get_browser_contents
    while !contents or (contents and !contents.match(needle)) && Time.now - start < limit
      contents = get_browser_contents
      sleep 0.1
    end
  end

  Redcar.gui.yield_until { started && !thread.alive? }

  # For now, just skip on XUL platforms on which we can't get browser exec results
  # (current version of SWT and XulRunner). More info at:
  # https://bugs.eclipse.org/bugs/show_bug.cgi?id=259687
  unless (contents.nil? or contents.empty?) and [:windows, :linux].include? Redcar.platform
    negation ? (contents.should_not match needle) : (contents.should match needle)
  end
end

When /^I click "([^\"]+)" in the HTML tab$/ do |link|
  html_view = focussed_tab.html_view
  # The JQuery way doesn't seem to work - I'm getting errors with this:
  # => html_view.controller.execute(%{ $("a:contains(#{link.gsub('"', '\"')})").click(); })
  # So, click the link the old-fashioned way.
  js = <<-JAVASCRIPT
    var link, evt, links, cancelled, i;
    links = document.getElementsByTagName("a");
    for (i = 0; i < links.length; i++) {
      if (links[i].innerHTML.search(#{link.inspect}) > -1) {
        link = links[i];
        break;
      }
    }

    if (typeof(link) !== "undefined") {
      if (document.createEvent) {
        evt = document.createEvent("MouseEvents");
        evt.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
        cancelled = !link.dispatchEvent(evt);
      } else if (link.fireEvent) {
        cancelled = !link.fireEvent("onclick");
      }
      if (!cancelled) {
        window.location = link.href;
      }
    }
  JAVASCRIPT

  html_view.controller.execute(js)
end

When /^I open the browser bar$/ do
  Redcar::HtmlView::OpenBrowserBar.new.run
end

When /^I open a web preview$/ do
  Redcar::HtmlView::FileWebPreview.new.run
end
