Then /^I should see "([^\"]*)" in the tree$/ do |rows|
  rows = rows.split(",").map {|r| r.strip}
  rows.each do |row|
    top_tree.items.include?(row).should be_true
  end
end
