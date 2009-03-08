Feature: EditTab
  
Scenario: Open an EditTab
  When I press "Super+N"
  Then there should be 1 EditTab open

Scenario: Choose Ruby syntax
  Given there is an EditTab open
  When I press "Ctrl+Alt+Shift+R" then "1"
  Then the current syntax should be "Ruby"

Scenario: Type some text
  Given there is an EditTab open with syntax "Ruby"
  When I type "def foo"
  Then I should see "def foo<c>" in the EditTab

Scenario: Move cursor left
  Given there is an EditTab open with syntax "Ruby"
  When I type "def foo"
  And I press "Left"
  Then I should see "def fo<c>o" in the EditTab
