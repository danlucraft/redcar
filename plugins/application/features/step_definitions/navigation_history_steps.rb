Then /^the focussed document path is "([^\"]*)"$/ do |path|
  doc = Redcar.app.focussed_window.focussed_notebook_tab_document
  doc.path.should == File.expand_path(path)
end