Feature: Kill Line

Scenario: Killing a single line
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbonne\nbaz"
  And I move the cursor to 5
  And I kill the line
  Then I should see "foo\nbonne\nbaz" in the edit tab
  And I should not see "bar" in the edit tab

Scenario: Killing a multi-line selection
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbonne\nbaz"
  And I select from 5 to 9
  And I kill the line
  Then I should see "foo\nbaz" in the edit tab
  And I should not see "bar" in the edit tab
  And I should not see "bonne" in the edit tab