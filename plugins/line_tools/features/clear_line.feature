Feature: Clear Line

Scenario: Clearing a single line
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbonne\nbaz"
  And I move the cursor to 5
  And I clear the line
  Then I should see "foo\n\nbonne\nbaz" in the edit tab
  And I should not see "bar" in the edit tab

Scenario: Clearing a multi-line selection
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbonne\nbaz"
  And I select from 5 to 9
  And I clear the line
  Then I should see "foo\n\nbaz" in the edit tab
  And I should not see "bar" in the edit tab
  And I should not see "bonne" in the edit tab