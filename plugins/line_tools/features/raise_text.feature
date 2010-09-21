Feature: Raise Text

Scenario: Raising a line swaps a line with its predecessor
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 5
  And I raise the text
  Then I should see "bar\nfoo\nbaz\nbonne" in the edit tab

Scenario: Raising a multi-line selection swaps it with the preceding line
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I select from 5 to 9
  And I raise the text
  Then I should see "bar\nbaz\nfoo\nbonne" in the edit tab

Scenario: The first line of a document cannot be raised
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 0
  And I raise the text
  Then I should see "foo\nbar\nbaz\nbonne" in the edit tab

Scenario: The second line should be able to be raised to become first
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 4
  And I raise the text
  Then I should see "bar\nfoo\nbaz\nbonne" in the edit tab

Scenario: The last line should be able to be raised to become second-to-last
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 12
  And I raise the text
  Then I should see "foo\nbar\nbonne\nbaz" in the edit tab

Scenario: A multi-line selection including the first line of a document cannot be raised
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I select from 0 to 5
  And I raise the text
  Then I should see "foo\nbar\nbaz\nbonne" in the edit tab
  
Scenario: Should work with unicode
  When I open a new edit tab
  And I replace the contents with "foo\nbść\nbaz\nbonne"
  And I move the cursor to 5
  And I raise the text
  Then the contents should be "bść\nfoo\nbaz\nbonne"