Feature: Shell commands
  As a user
  I want to be able to extend Redcar using shell scripts

  Scenario: Ruby/ Toggle string symbol
    Given there is an EditTab open with syntax "Ruby"
    When I type "p :foo"
    And I press "Left"
    And I press "Ctrl+Shift+:"
    Then I should see "p \"f<c>oo\"" in the EditTab

  Scenario: Text/ Duplicate line/selection
    Given there is an EditTab open with syntax "Ruby"
    When I type "foo\nbar\n"
    And I press "Up" then "Up"
    And I press "Ctrl+Shift+D"
    Then I should see "foo\n<c>foo\nbar" in the EditTab
    
