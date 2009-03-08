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

Scenario: Up
  Given there is an EditTab open with syntax "Ruby"
  When I type "def foo\np :foo\nend"
  And I press "Up"
  Then I should see "p<c> :foo" in the EditTab

Scenario: Page up
  Given there is an EditTab open with syntax "Ruby"
  When I type "def foo"
  And I press "Page_Up"
  Then I should see "<c>def foo" in the EditTab

Scenario: Move to line start
  Given there is an EditTab open with syntax "Ruby"
  When I type "def foo"
  And I press "Ctrl+A"
  Then I should see "<c>def foo" in the EditTab

Scenario: Move to line end
  Given there is an EditTab open with syntax "Ruby"
  When I type "def foo"
  And I press "Left" then "Left"
  And I press "Ctrl+E"
  Then I should see "def foo<c>" in the EditTab
