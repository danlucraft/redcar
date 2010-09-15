Feature: Replace current line with clipboard contents

Scenario: Replacing the current line
  When I open a new edit tab
  And I replace the contents with "21 eggs\n7 chickens\n3 henhouses\n1 farmer"
  And I copy text
  And I move the cursor to 10
  And I replace the line
  Then I should see "21 eggs\n21 eggs\n3 henhouses\n1 farmer" in the edit tab
  And I should not see "7 chickens" in the edit tab

Scenario: Replacing the current line with an empty clipboard
  When I open a new edit tab
  And I replace the contents with "21 eggs\n7 chickens\n3 henhouses\n1 farmer"
  And I replace the line
  Then I should see "21 eggs\n7 chickens\n3 henhouses\n1 farmer" in the edit tab

Scenario: Replacing the current selection
  When I open a new edit tab
  And I replace the contents with "21 eggs\n7 chickens\n3 henhouses\n1 farmer"
  And I select from 19 to 31
  And I copy text
  And I move the cursor to 10
  And I replace the line
  Then I should see "21 eggs\n3 henhouses\n3 henhouses\n1 farmer" in the edit tab
