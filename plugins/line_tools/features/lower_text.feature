Feature: Lower Text

Scenario: Lowering a single line
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 5
  And I lower the text
  Then I should see "foo\nbaz\nbar\nbonne" in the edit tab

Scenario: Lowering a multi-line selection
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I select from 5 to 9
  And I lower the text
  Then I should see "foo\nbonne\nbar\nbaz" in the edit tab
  And the selected text should be "bar\nbaz"

Scenario: Lowering the last line of a document
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 12
  And I lower the text
  Then I should see "foo\nbar\nbaz\nbonne" in the edit tab
  And I should not see "foo\nbar\nbaz\n\nbonne" in the edit tab

Scenario: Lowering the first line of a document
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 0
  And I lower the text
  Then I should see "bar\nfoo\nbaz\nbonne" in the edit tab

Scenario: Lowering the second-to-last line of a document
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 8
  And I lower the text
  Then I should see "foo\nbar\nbonne\nbaz" in the edit tab

Scenario: Lowering a multi-line selection including the last line of a document
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I select from 8 to 12
  And I lower the text
  Then I should see "foo\nbar\nbonne\nbaz" in the edit tab
  And I should not see "foo\nbar\n\nbaz\nbonne" in the edit tab
  And the selected text should be "baz"

Scenario: Should work with unicode
  When I open a new edit tab
  And I replace the contents with "foo\nbść\nbaz\nbonne"
  And I move the cursor to 5
  And I lower the text
  Then the contents should be "foo\nbaz\nbść\nbonne"
