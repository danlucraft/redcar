
When /I wait (?:for )?(\d)(?: seconds)?/ do |num|
  sleep num.to_i
end
