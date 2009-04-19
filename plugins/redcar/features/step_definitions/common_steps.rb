
When /I wait (?:for )?(\d+)(?: seconds)?/ do |num|
  sleep num.to_i
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
