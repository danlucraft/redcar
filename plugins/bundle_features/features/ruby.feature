Feature: Ruby Bundle
  As a user
  I want to make use of all the Ruby commands

  Background:
    Given there is an EditTab open with syntax "Ruby"

  Scenario: Run
    Given the EditTab contains "p :abracadabra"
    And I press "Super+R"
    Then there should be one HtmlTab open
    And I should see "abracadabra" in the HtmlTab

#  Scenario: Open require
#    Given the EditTab contains "require 'open4'"
#    And I press "Ctrl+E"
#    And I press "Left" then "Left"
#    And I press "Super+Shift+D"
#    And I wait 1 seconds
#    And I wait 1 seconds
#    And I wait 1 seconds
#    And I wait 1 seconds
#    Then there should be 2 EditTabs open
#    And I should see "module Open4" in the EditTab "open4.rb"
