

Then /^the (.*) speedbar should be open$/ do |class_name|
  Redcar.app.focussed_window.speedbar.class.to_s.should == class_name
end
