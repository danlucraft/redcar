Feature: EditTab
  As a user
  I want to open tabs for editing my code

Scenario: Open an EditTab
  When I press "Super+N"
  Then there should be 1 EditTab open

Scenario: Choose Ruby syntax
  Given there is an EditTab open
  When I press "Ctrl+Alt+Shift+R" then "1"
  Then the current syntax should be "Ruby"
