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

Scenario: Trimming a line with unicode
  When I open a new edit tab
  And I replace the contents with "foo\nbść\nbaz"
  And I move the cursor to 5
  And I trim the line
  Then the contents should be "foo\nb\nbaz"

Scenario: Trimming a line with Windows line endings
  When I open a new edit tab
  And I replace the contents with "foo\r\nbść\r\nbaz"
  And I move the cursor to 6
  And I trim the line
  Then the contents should be "foo\r\nb\r\nbaz"

Scenario: Trimming empty line removes newline character
  When I open a new edit tab
  And I replace the contents with "foo\n\nbaz"
  And I move the cursor to 4
  And I trim the line
  Then the contents should be "foo\nbaz"

Scenario: Trimming empty line removes newline character (Windows)
  When I open a new edit tab
  And I replace the contents with "foo\r\n\r\nbaz"
  And I move the cursor to 5
  And I trim the line
  Then the contents should be "foo\r\nbaz"

Scenario: Trimming when at end of line removes newline character
  When I open a new edit tab
  And I replace the contents with "foo\nbść\nbaz"
  And I move the cursor to 7
  And I trim the line
  Then the contents should be "foo\nbśćbaz"

Scenario: Trimming when at end of file and newline absent it does nothing
  When I open a new edit tab
  And I replace the contents with "foo\nbść\nbaz"
  And I move the cursor to 11
  And I trim the line
  Then the contents should be "foo\nbść\nbaz"

Scenario: Trimming when just before last newline character it removes it
  When I open a new edit tab
  And I replace the contents with "foo\nbść\nbaz\n"
  And I move the cursor to 11
  And I trim the line
  Then the contents should be "foo\nbść\nbaz"

Scenario: Trimming when at end of file and newline present it does nothing
  When I open a new edit tab
  And I replace the contents with "foo\nbść\nbaz\n"
  And I move the cursor to 12
  And I trim the line
  Then the contents should be "foo\nbść\nbaz\n"
