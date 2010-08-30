Feature: Replace current line with clipboard contents

Scenario: Replacing the current line
  When I open a new edit tab
  And I replace the contents with "21 eggs\n7 chickens\n3 henhouses\n1 farmer"
  And I copy text
  And I move the cursor to 10
  And I replace the line
  Then I should see "21 eggs\n21 eggs\n3 henhouses\n1 farmer" in the edit tab

Scenario: Replacing the current line with an empoty clipboard
  When I open a new edit tab
  And I replace the contents with "21 eggs\n7 chickens\n3 henhouses\n1 farmer"
  And I replace the line
  Then I should see "21 eggs\n7 chickens\n3 henhouses\n1 farmer" in the edit tab

Scenario: Replacing the current selection
  When I open a new edit tab
  And I replace the contents with "21 eggs\n7 chickens\n3 henhouses\n1 farmer"
  And I select from 20 to 30
  And I copy text
  And I move the cursor to 10
  And I replace the line
  Then I should see "21 eggs\n3 henhouses\n1 farmer\n3 henhouses\n1 farmer" in the edit tab
