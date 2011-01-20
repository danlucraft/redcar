# Because the Find speedbar and the find operations of the Find and Replace speedbar are supposed to
# function identically, all scenarios here should be copied to find_and_replace.feature, with the
# references to OpenFindSpeedbarCommand and FindSpeedbar adjusted accordingly.

@speedbar
Feature: Find

  Background:
    Given I open a new edit tab

  Scenario: Open Find speedbar
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    Then I should see the find speedbar

  Scenario: Change settings
    When I open the find speedbar
    And I choose "Plain" in the "query_type" field in the speedbar
    And I uncheck "Match case" in the speedbar
    And I check "Wrap around" in the speedbar
    Then "Plain" should be chosen in the "query_type" field in the speedbar
    And "Match case" should not be checked in the speedbar
    And "Wrap around" should be checked in the speedbar

  Scenario: Search for a word should select next occurrence
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Bar" into the "Find" field in the speedbar
    Then the selected text should be "Bar"

  Scenario: Search twice should move to the next occurrence
    When I replace the contents with "Foo\nBar\nFoo"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selection should be on line 0
    When I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 2

  Scenario: Search should incrementally update
    When I replace the contents with "Foo\nBaar\nBaaz"
    And I move the cursor to 0
    And I open the find speedbar
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
    And I open the find speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"

  Scenario: Search for a word should find occurrence after the cursor
    When I replace the contents with "Foo\nBar\nBaz\nFoo"
    And I move the cursor to 1
    And I open the find speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selection should be on line 3
    And the selected text should be "Foo"
    When I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0

  Scenario: Search for a word should wrap to earlier occurrence if none left
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 1
    And I open the find speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0

  Scenario: Doesn't search for a regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Ba." into the "Find" field in the speedbar
    Then there should not be any text selected

  Scenario: Search for a regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Ba." into the "Find" field in the speedbar
    And I choose "Regex" in the "query_type" field in the speedbar
    Then the selected text should be "Bar"
    When I press "Next" in the speedbar
    Then the selected text should be "Baz"

  # Current Settings: Regex, No Match case, Wrap around

  Scenario: Search for a regex matches a second time
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Ba." into the "Find" field in the speedbar
    And I choose "Regex" in the "query_type" field in the speedbar
    Then the selected text should be "Bar"
    When I press "Next" in the speedbar
    Then the selected text should be "Baz"

  Scenario: Doesn't search for a glob
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Ba*" into the "Find" field in the speedbar
    Then there should not be any text selected

  Scenario: Search for a glob
    When I replace the contents with "Foo\nBar none I said\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Ba*" into the "Find" field in the speedbar
    And I choose "Glob" in the "query_type" field in the speedbar
    Then the selected text should be "Bar none I said"
    When I press "Next" in the speedbar
    Then the selected text should be "Baz"

  Scenario: Should not match case if unset
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should not match case if unset with regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I choose "Regex" in the "query_type" field in the speedbar
    And I type "fo." into the "Find" field in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should not match case if unset with glob
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I choose "Glob" in the "query_type" field in the speedbar
    And I type "fo*" into the "Find" field in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should match case if requested
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I choose "Plain" in the "query_type" field in the speedbar
    And I uncheck "Match case" in the speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    When I check "Match case" in the speedbar
    Then there should not be any text selected

  Scenario: Should match case if requested with regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I choose "Regex" in the "query_type" field in the speedbar
    And I uncheck "Match case" in the speedbar
    And I type "fo." into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    When I check "Match case" in the speedbar
    Then there should not be any text selected

  Scenario: Should match case if requested with glob
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I choose "Glob" in the "query_type" field in the speedbar
    And I uncheck "Match case" in the speedbar
    And I type "fo*" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    When I check "Match case" in the speedbar
    Then there should not be any text selected

  Scenario: Find next with wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3

   Scenario: Find next without wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I uncheck "Wrap around" in the speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And there should not be any text selected

  Scenario: Find previous with wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 18
    And I open the find and replace speedbar
    And I uncheck "Wrap around" in the speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And there should not be any text selected
    When I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I check "Wrap around" in the speedbar
    And I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11

  Scenario: Find previous without wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 18
    And I open the find and replace speedbar
    And I uncheck "Wrap around" in the speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And there should not be any text selected
    When I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And there should not be any text selected

  Scenario: Should scroll vertically to the match
    When I replace the contents with 100 lines of "xxx" then "Foo"
    And I scroll to the top of the document
    And I move the cursor to 0
    And I open the find speedbar
    And I uncheck "Wrap around" in the speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    And line number 100 should be visible

  Scenario: "Should scroll horizontally to the match"
    When I replace the contents with 300 "x" then "Foo"
    And I move the cursor to 0
    And I open the find speedbar
    And I uncheck "Wrap around" in the speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    And horizontal offset 302 should be visible

  Scenario: Should reopen with the same text as the previous search
    When I open the find speedbar
    And I type "foo" into the "Find" field in the speedbar
    And I close the speedbar
    And I open the find speedbar
    Then the "Find" field in the speedbar should have text "foo"

  Scenario: Should reopen with the same value of query type as the previous search
    When I open the find speedbar
    And I choose "Plain" in the "query_type" field in the speedbar
    And I close the speedbar
    And I open the find speedbar
    Then "Plain" should be chosen in the "query_type" field in the speedbar
    When I choose "Regex" in the "query_type" field in the speedbar
    And I close the speedbar
    And I open the find speedbar
    Then "Regex" should be chosen in the "query_type" field in the speedbar
    When I open the find speedbar
    And I choose "Glob" in the "query_type" field in the speedbar
    And I close the speedbar
    And I open the find speedbar
    Then "Glob" should be chosen in the "query_type" field in the speedbar

  Scenario: Should reopen with the same value of Match case as the previous search
    When I open the find speedbar
    And I check "Match case" in the speedbar
    And I close the speedbar
    And I open the find speedbar
    Then "Match case" should be checked in the speedbar
    When I uncheck "Match case" in the speedbar
    And I close the speedbar
    And I open the find speedbar
    Then "Match case" should not be checked in the speedbar

  Scenario: Should reopen with the same value of Wrap around as the previous search
    And I open the find speedbar
    And I check "Wrap around" in the speedbar
    And I close the speedbar
    And I open the find speedbar
    Then "Wrap around" should be checked in the speedbar
    When I uncheck "Wrap around" in the speedbar
    And I close the speedbar
    And I open the find speedbar
    Then "Wrap around" should not be checked in the speedbar

  Scenario: Should initialize query with the currently selected text
    When I replace the contents with "Flux\nBar\nFoo"
    And I move the cursor to 0
    And I select from 0 to 4
    And I open the find speedbar
    Then the "Find" field in the speedbar should have text "Flux"

  Scenario: Search for a word should start from the start of a selection
    When I replace the contents with "Foo\nBar\nBaz"
    And I select from 5 to 8
    And I open the find speedbar
    And I type "Ba" into the "Find" field in the speedbar
    Then the selected text should be "Ba"
    And the selection should be on line 2

  Scenario: Should match the next occurence of the currently selected text
    When I replace the contents with "Foo\nBar\nFoo"
    And I move the cursor to 0
    And I select from 0 to 3
    And I open the find speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And line number 2 should be visible