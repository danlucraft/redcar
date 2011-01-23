# Note: Most scenarios in this file can and should be adapted for the Find speedbar and added to
# find.feature. Aside from different names, the tests will need to be adjusted to not rely on
# incremental updating of query matches.

@speedbar
Feature: Incremental Search

  Background:
    Given I open a new edit tab

  Scenario: Open Incremental Search speedbar
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    Then I should see the incremental search speedbar

  Scenario: Search for a word should select next occurrence
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "Bar" into the "Find" field in the speedbar
    Then the selected text should be "Bar"

  Scenario: Search twice should move to the next occurrence
    When I replace the contents with "Foo\nBar\nFoo"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selection should be on line 0
    When I open the incremental search speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 2

  Scenario: Search should incrementally update
    When I replace the contents with "Foo\nBaar\nBaaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "Ba" into the "Find" field in the speedbar
    Then the selected text should be "Ba"
    And the selection should be on line 1
    When I type "Baa" into the "Find" field in the speedbar
    And the selection should be on line 1
    When I type "Baaz" into the "Find" field in the speedbar
    Then the selected text should be "Baaz"
    And the selection should be on line 2
    When I type "Baa" into the "Find" field in the speedbar
    Then the selection should be on line 2

  Scenario: Search for a word adjacent to cursor should select word
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"

  Scenario: Search for a word should find occurrence after the cursor
    When I replace the contents with "Foo\nBar\nBaz\nFoo"
    And I move the cursor to 1
    And I open the incremental search speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selection should be on line 3
    And the selected text should be "Foo"
    When I open the incremental search speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0

  Scenario: Search for a word should wrap to earlier occurrence if none left
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 1
    And I open the incremental search speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0

  Scenario: Not thrown off by multi-byte characters
    When I replace the contents with "Benedikt Müller"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "ler" into the "Find" field in the speedbar
    Then the selected text should be "ler"
    And the selection range should be from 12 to 15

  Scenario: Not thrown off by multi-byte characters 2
    When I replace the contents with "Benedikt Müller\n foo "
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the selected text should be "foo"
    And the selection range should be from 17 to 20

  Scenario: Not thrown off by multi-byte characters 3
    When I replace the contents with "你好, 凯兰\nYou make my heart super happy."
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "you" into the "Find" field in the speedbar
    Then the selected text should be "You"
    And the selection range should be from 7 to 10

  Scenario: Handles repeated search across by multi-byte characters
    When I replace the contents with "Foo\n你好, 凯兰\nFoo\nBar\nFoo\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0
    When I open the incremental search speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 2
    When I open the incremental search speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 4
    When I open the incremental search speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0
    When I open the incremental search speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 2

  Scenario: Should select multi-byte characters
    When I replace the contents with "Benedikt Müller"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "mül" into the "Find" field in the speedbar
    Then the selected text should be "Mül"
    And the selection range should be from 9 to 12

  Scenario: Should select multi-byte characters
    When I replace the contents with "Benedikt Müller"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "mül" into the "Find" field in the speedbar
    Then the selected text should be "Mül"
    And the selection range should be from 9 to 12

  Scenario: Should select multi-byte characters 2
    When I replace the contents with "你好, 凯兰\nYou make my heart super happy."
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "凯兰" into the "Find" field in the speedbar
    Then the selected text should be "凯兰"
    And the selection range should be from 4 to 6

  Scenario: Doesn't search for a regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "Ba." into the "Find" field in the speedbar
    Then there should not be any text selected

  Scenario: Search for a regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "Ba." into the "Find" field in the speedbar
    Then there should not be any text selected
    When I check "Regex" in the speedbar
    Then the selected text should be "Bar"
    When I open the incremental search speedbar
    Then the selected text should be "Baz"

  Scenario: Search for a regex matches a second time
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "Ba." into the "Find" field in the speedbar
    Then there should not be any text selected
    When I check "Regex" in the speedbar
    Then the selected text should be "Bar"
    When I open the incremental search speedbar
    Then the selected text should be "Baz"

  Scenario: Should not match case by default
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should not match case with regex by default
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "fo." into the "Find" field in the speedbar
    Then there should not be any text selected
    When I check "Regex" in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should match case if requested
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    When I check "Match case" in the speedbar
    Then there should not be any text selected
    When I type "Foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should match case if requested with regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I check "Regex" in the speedbar
    And I type "fo." into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    When I check "Match case" in the speedbar
    Then there should not be any text selected

  Scenario: Repeat incremental search with wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I open the incremental search speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I open the incremental search speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3

   Scenario: Repeat incremental search without wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I uncheck "Wrap around" in the speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I open the incremental search speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I open the incremental search speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And there should not be any text selected

  Scenario: Find next with wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I run the command Redcar::DocumentSearch::DoFindNextCommand
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I run the command Redcar::DocumentSearch::DoFindNextCommand
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3

   Scenario: Find next without wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I uncheck "Wrap around" in the speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I run the command Redcar::DocumentSearch::DoFindNextCommand
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I run the command Redcar::DocumentSearch::DoFindNextCommand
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And there should not be any text selected

  Scenario: Find previous with wrap around by default
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 18
    And I open the incremental search speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I run the command Redcar::DocumentSearch::DoFindPreviousCommand
    Then the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I run the command Redcar::DocumentSearch::DoFindPreviousCommand
    Then the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I run the command Redcar::DocumentSearch::DoFindPreviousCommand
    Then the selected text should be "Foo"
    And the selection range should be from 8 to 11

  Scenario: Find previous without wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 18
    And I open the incremental search speedbar
    And I uncheck "Wrap around" in the speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And there should not be any text selected
    When I run the command Redcar::DocumentSearch::DoFindPreviousCommand
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I run the command Redcar::DocumentSearch::DoFindPreviousCommand
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I run the command Redcar::DocumentSearch::DoFindPreviousCommand
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And there should not be any text selected

  Scenario: Should scroll vertically to the match
    When I replace the contents with 100 lines of "xxx" then "Foo"
    And I scroll to the top of the document
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    And line number 100 should be visible

  Scenario: "Should scroll horizontally to the match"
    When I replace the contents with 300 "x" then "Foo"
    And I move the cursor to 0
    And I open the incremental search speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    And horizontal offset 302 should be visible

  Scenario: Should not reopen with the same text as the previous search
    When I open the incremental search speedbar
    And I type "foo" into the "Find" field in the speedbar
    And I close the speedbar
    And I open the incremental search speedbar
    Then the "Find" field in the speedbar should have text ""

  Scenario: Should not initialize query with the currently selected text
    When I replace the contents with "Flux\nBar\nFoo"
    And I move the cursor to 0
    And I select from 0 to 4
    And I open the incremental search speedbar
    Then the "Find" field in the speedbar should have text ""

  Scenario: Search for a word should start from the start of a selection
    When I replace the contents with "Foo\nBar\nBaz"
    And I select from 5 to 8
    And I open the incremental search speedbar
    And I type "Ba" into the "Find" field in the speedbar
    Then the selected text should be "Ba"
    And the selection should be on line 2
