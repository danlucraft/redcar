# Feature: Ruby on Rails bundle
#   As a user
#   I want to make use of all the Ruby commands
# 
#   Background:
#     Given the ProjectTab is open with the Blog Rails project
#     And there is an EditTab open with syntax "Ruby on Rails"
# 
#   Scenario: Generate Quick Migration
#     When I press "Ctrl+Shift+M"
#     And I give the "Quick Migration Generator" String dialog the input "User"
#     Then the glob "plugins/bundle_features/features/fixtures/blog/db/migrate/*_user*" should not be empty
# 
#   Scenario: T
#     When I press "T"    
