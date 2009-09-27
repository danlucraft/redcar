
Given /^the ProjectTab is open with the (\w+) Rails project$/ do |project|
  Given "the ProjectTab is open"
  And "I have added the directory \"plugins/bundle_features/features/fixtures/#{project}\" to the ProjectTab"
end
