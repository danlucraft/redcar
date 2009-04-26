
When /I wait (?:for )?(\d+)(?: seconds?)?/ do |num|
  sleep num.to_i
end

When /I wait a tick/ do
  sleep 1
end

Given /^the file "([^"]+)" does not exist$/ do |filename|
  FileUtils.rm_f(filename)
end

Given /^the file #{FeaturesHelper::STRING_RE} contains #{FeaturesHelper::STRING_RE}$/ do |filename, contents|
  File.open(filename, "w") do |f|
    f.puts contents
  end
end

Then /^the file #{FeaturesHelper::STRING_RE} should contain #{FeaturesHelper::STRING_RE}$/ do |filename, contents|
  IO.read(filename).chomp.should == contents
end

Then /^the file #{FeaturesHelper::STRING_RE} should not exist$/ do |filename|
  File.exist?(Redcar::ROOT + filename).should_not be_true
end

