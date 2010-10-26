
Then /^the window should have title "([^\"]*)"$/ do |expected_title|
  active_shell.get_text.should == expected_title
end

When /^I manually widen the treebook (only a few pixels|to show the sash)$/ do |w|
  if w =~ /^only/
    focussed_window.controller.send(:set_sash_widths, Redcar::ApplicationSWT::Window::SASH_WIDTH-1)
  else
    focussed_window.controller.send(:set_sash_widths, Redcar::ApplicationSWT::Window::SASH_WIDTH)
  end
end
