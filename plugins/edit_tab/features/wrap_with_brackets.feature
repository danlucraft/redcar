Feature: Type " or ( to wrap selection with parentheses

  Background:
    Given there is an EditTab open

  Scenario: Type " to wrap selection
    When I type "Ah"
    And I press "Shift+Left" then "Shift+Left"
    Then I should see "<c>Ah<s>" in the EditTab

  Scenario: T
    When I type "asdf"
