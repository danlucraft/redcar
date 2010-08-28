Feature: Line Tools

Scenario: Raising a line swaps a line with its predecessor
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 5
  And I run the command Redcar::LineTools::RaiseTextCommand
  Then I should see "bar\nfoo\nbaz\nbonne" in the edit tab

Scenario: Raising a multi-line selection swaps it with the preceding line
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I select from 5 to 9
  And I run the command Redcar::LineTools::RaiseTextCommand
  Then I should see "bar\nbaz\nfoo\nbonne" in the edit tab

Scenario: The first line of a document cannot be raised
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 0
  And I run the command Redcar::LineTools::RaiseTextCommand
  Then I should see "foo\nbar\nbaz\nbonne" in the edit tab

Scenario: Lowering a line swaps a line with its follower
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 5
  And I run the command Redcar::LineTools::LowerTextCommand
  Then I should see "foo\nbaz\nbar\nbonne" in the edit tab

Scenario: Lowering a multi-line selection swaps it with the following line
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I select from 5 to 9
  And I run the command Redcar::LineTools::LowerTextCommand
  Then I should see "foo\nbonne\nbar\nbaz" in the edit tab

Scenario: The last line of a document cannot be lowered
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 12
  And I run the command Redcar::LineTools::LowerTextCommand
  Then I should see "foo\nbar\nbaz\nbonne" in the edit tab

# Edge Cases - need extra handling
Scenario: The second line should be able to be raised to become first
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 4
  And I run the command Redcar::LineTools::RaiseTextCommand
  Then I should see "bar\nfoo\nbaz\nbonne" in the edit tab

Scenario: The first line should be able to be lowered to become second
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 0
  And I run the command Redcar::LineTools::LowerTextCommand
  Then I should see "bar\nfoo\nbaz\nbonne" in the edit tab

Scenario: The second-to-last line should be able to be lowered to become last
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 8
  And I run the command Redcar::LineTools::LowerTextCommand
  Then I should see "foo\nbar\nbonne\baz" in the edit tab

Scenario: The last line should be able to be raised to become second-to-last
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I move the cursor to 12
  And I run the command Redcar::LineTools::RaiseTextCommand
  Then I should see "foo\nbar\nbonne\baz" in the edit tab

Scenario: A multi-line selection including the last line of a document cannot be lowered
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I select from 8 to 12
  And I run the command Redcar::LineTools::LowerTextCommand
  Then I should see "foo\nbar\nbaz\nbonne" in the edit tab

Scenario: A multi-line selection including the first line of a document cannot be raised
  When I open a new edit tab
  And I replace the contents with "foo\nbar\nbaz\nbonne"
  And I select from 0 to 5
  And I run the command Redcar::LineTools::RaiseTextCommand
  Then I should see "foo\nbar\nbaz\nbonne" in the edit tab