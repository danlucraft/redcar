
Then /^the window should have title "([^\"]*)"$/ do |expected_title|
  Swt.sync_exec do
    active_shell.get_text.should == expected_title
  end
end

When /^I set the treebook width to (the default|only a few pixels|the minimum width|\d+ pixels)$/ do |w|
  Swt.sync_exec do
    if w == "only a few pixels"
      width = 10
    elsif w == "the minimum width"
      width = Redcar::ApplicationSWT::Window::MINIMUM_TREEBOOK_WIDTH
    elsif w == "the default"
      width = default_treebook_width
    else
      width = w.split(" ")[0].to_i
    end
    focussed_window.controller.send(:set_sash_widths, width)
  end
end
