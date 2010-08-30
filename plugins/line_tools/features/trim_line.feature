Feature: Trim line

Scenario: Trimming a single line
  When I open a new edit tab
  And I replace the contents with "Once upon a time"
  And I move the cursor to 4
  And I trim the line
  Then I should see "Once" in the edit tab
  And I should not see "upon a time" in the edit tab

Scenario: Trimming a selection
  When I open a new edit tab
  And I replace the contents with "Once upon a time"
  And I select from 5 to 9
  And I trim the line
  Then I should see "Once " in the edit tab
  And I should not see "upon a time" in the edit tab
