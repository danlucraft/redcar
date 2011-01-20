# Because the Find speedbar and the find operations of the Find and Replace speedbar are supposed to
# function identically, all scenarios from find.feature should be copied here, with the references
# to OpenFindSpeedbarCommand and FindSpeedbar adjusted accordingly.

@speedbar
Feature: Find and Replace

  Background:
    Given I open a new edit tab

  Scenario: Open Find and Replace speedbar
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    Then I should see the find and replace speedbar

  Scenario: Change settings
    When I open the find and replace speedbar
    And I choose "Plain" in the "query_type" field in the speedbar
    And I uncheck "Match case" in the speedbar
    And I check "Wrap around" in the speedbar
    Then "Plain" should be chosen in the "query_type" field in the speedbar
    And "Match case" should not be checked in the speedbar
    And "Wrap around" should be checked in the speedbar

  # Current Settings: Plain, No Match case, Wrap around

  Scenario: Search for a word should select next occurrence
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I type "Bar" into the "Find" field in the speedbar
    Then the selected text should be "Bar"

  Scenario: Search twice should move to the next occurrence
    When I replace the contents with "Foo\nBar\nFoo"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selection should be on line 0
    When I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 2

  Scenario: Search should incrementally update
    When I replace the contents with "Foo\nBaar\nBaaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
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
    And I open the find and replace speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"

  Scenario: Search for a word should find occurrence after the cursor
    When I replace the contents with "Foo\nBar\nBaz\nFoo"
    And I move the cursor to 1
    And I open the find and replace speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selection should be on line 3
    And the selected text should be "Foo"
    When I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0

  Scenario: Search for a word should wrap to earlier occurrence if none left
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 1
    And I open the find and replace speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0

  Scenario: Doesn't search for a regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I type "Ba." into the "Find" field in the speedbar
    Then there should not be any text selected

  Scenario: Search for a regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I type "Ba." into the "Find" field in the speedbar
    And I choose "Regex" in the "query_type" field in the speedbar
    Then the selected text should be "Bar"
    When I press "Next" in the speedbar
    Then the selected text should be "Baz"

  Scenario: Search for a regex matches a second time
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I type "Ba." into the "Find" field in the speedbar
    And I choose "Regex" in the "query_type" field in the speedbar
    Then the selected text should be "Bar"
    When I press "Next" in the speedbar
    Then the selected text should be "Baz"

  Scenario: Doesn't search for a glob
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I choose "Plain" in the "query_type" field in the speedbar
    And I type "Ba*" into the "Find" field in the speedbar
    Then there should not be any text selected

  Scenario: Search for a glob
    When I replace the contents with "Foo\nBar none I said\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I type "Ba*" into the "Find" field in the speedbar
    And I choose "Glob" in the "query_type" field in the speedbar
    Then the selected text should be "Bar none I said"
    When I press "Next" in the speedbar
    Then the selected text should be "Baz"

  Scenario: Should not match case if unset
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I choose "Plain" in the "query_type" field in the speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should not match case if unset with regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I choose "Regex" in the "query_type" field in the speedbar
    And I type "fo." into the "Find" field in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should not match case if unset with glob
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I choose "Glob" in the "query_type" field in the speedbar
    And I type "fo*" into the "Find" field in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should match case if requested
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I choose "Plain" in the "query_type" field in the speedbar
    And I uncheck "Match case" in the speedbar
    And I type "foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    When I check "Match case" in the speedbar
    Then there should not be any text selected

  Scenario: Should match case if requested with regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I choose "Regex" in the "query_type" field in the speedbar
    And I uncheck "Match case" in the speedbar
    And I type "fo." into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    When I check "Match case" in the speedbar
    Then there should not be any text selected

  Scenario: Should match case if requested with glob
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I choose "Glob" in the "query_type" field in the speedbar
    And I uncheck "Match case" in the speedbar
    And I type "fo*" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    When I check "Match case" in the speedbar
    Then there should not be any text selected

  Scenario: Reset settings
    When I open the find and replace speedbar
    And I choose "Plain" in the "query_type" field in the speedbar
    And I uncheck "Match case" in the speedbar
    And I check "Wrap around" in the speedbar
    Then "Plain" should be chosen in the "query_type" field in the speedbar
    And "Match case" should not be checked in the speedbar
    And "Wrap around" should be checked in the speedbar

  Scenario: Find next with wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 0
    And I open the find and replace speedbar
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
    And I open the find and replace speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    And line number 100 should be visible

  Scenario: "Should scroll horizontally to the match"
    When I replace the contents with 300 "x" then "Foo"
    And I move the cursor to 0
    And I open the find and replace speedbar
    And I type "Foo" into the "Find" field in the speedbar
    Then the selected text should be "Foo"
    And horizontal offset 302 should be visible

  Scenario: Should reopen with the same text as the previous search
    When I open the find and replace speedbar
    And I type "foo" into the "Find" field in the speedbar
    And I close the speedbar
    And I open the find and replace speedbar
    Then the "Find" field in the speedbar should have text "foo"

  Scenario: Should reopen with the same value of query type as the previous search
    When I open the find and replace speedbar
    And I choose "Plain" in the "query_type" field in the speedbar
    And I close the speedbar
    And I open the find and replace speedbar
    Then "Plain" should be chosen in the "query_type" field in the speedbar
    When I choose "Regex" in the "query_type" field in the speedbar
    And I close the speedbar
    And I open the find and replace speedbar
    Then "Regex" should be chosen in the "query_type" field in the speedbar
    When I open the find and replace speedbar
    And I choose "Glob" in the "query_type" field in the speedbar
    And I close the speedbar
    And I open the find and replace speedbar
    Then "Glob" should be chosen in the "query_type" field in the speedbar

  Scenario: Should reopen with the same value of Match case as the previous search
    When I open the find and replace speedbar
    And I check "Match case" in the speedbar
    And I close the speedbar
    And I open the find and replace speedbar
    Then "Match case" should be checked in the speedbar
    When I uncheck "Match case" in the speedbar
    And I close the speedbar
    And I open the find and replace speedbar
    Then "Match case" should not be checked in the speedbar

  Scenario: Should reopen with the same value of Wrap around as the previous search
    And I open the find and replace speedbar
    And I check "Wrap around" in the speedbar
    And I close the speedbar
    And I open the find and replace speedbar
    Then "Wrap around" should be checked in the speedbar
    When I uncheck "Wrap around" in the speedbar
    And I close the speedbar
    And I open the find and replace speedbar
    Then "Wrap around" should not be checked in the speedbar

  Scenario: Should initialize query with the currently selected text
    When I replace the contents with "Flux\nBar\nFoo"
    And I move the cursor to 0
    And I select from 0 to 4
    And I open the find and replace speedbar
    Then the "Find" field in the speedbar should have text "Flux"

  Scenario: Search for a word should start from the start of a selection
    When I replace the contents with "Foo\nBar\nBaz"
    And I select from 5 to 8
    And I open the find and replace speedbar
    And I type "Ba" into the "Find" field in the speedbar
    Then the selected text should be "Ba"
    And the selection should be on line 2

  Scenario: Should match the next occurence of the currently selected text
    When I replace the contents with "Foo\nBar\nFoo"
    And I move the cursor to 0
    And I select from 0 to 3
    And I open the find and replace speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And line number 2 should be visible

  # End of scenarios copied from Find speedbar

  # Begin of scenarios specific to Find and Replace speedbar

  Scenario: Reset settings for Find and Replace
    When I open the find and replace speedbar
    And I choose "Plain" in the "query_type" field in the speedbar
    And I uncheck "Match case" in the speedbar
    And I check "Wrap around" in the speedbar
    Then "Plain" should be chosen in the "query_type" field in the speedbar
    And "Match case" should not be checked in the speedbar
    And "Wrap around" should be checked in the speedbar

  Scenario: Open find and replace speedbar with initial selection
    When I replace the contents with "Foo\nBar\nBaz"
    And I select from 4 to 7
    And I open the find and replace speedbar
    Then the "Find" field in the speedbar should have text "Bar"
    When I type "Foo" into the "Replace" field in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nFoo\nBaz"
    And there should not be any text selected

  # Scenario: Find next with wrap around
  #   When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
  #   And I move the cursor to 0
  #   And I open the find and replace speedbar
  #   And I type "Foo" into the "Find" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I check "Wrap Around" in the speedbar
  #   And I press "Next" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 0 to 3
  #   When I press "Next" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 8 to 11
  #   When I press "Next" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 0 to 3
  #
  #  Scenario: Find next without wrap around
  #   When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
  #   And I move the cursor to 0
  #   And I open the find and replace speedbar
  #   And I type "Foo" into the "Find" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I uncheck "Wrap Around" in the speedbar
  #   And I press "Next" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 0 to 3
  #   When I press "Next" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 8 to 11
  #   When I press "Next" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be ""
  #   And the selection range should be from 11 to 11
  #
  # Scenario: Find previous with wrap around
  #   When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
  #   And I move the cursor to 18
  #   And I open the find and replace speedbar
  #   And I type "Foo" into the "Find" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I check "Wrap Around" in the speedbar
  #   And I press "Previous" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 8 to 11
  #   When I press "Previous" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 0 to 3
  #   When I press "Previous" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 8 to 11
  #
  # Scenario: Find previous without wrap around
  #   When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
  #   And I move the cursor to 18
  #   And I open the find and replace speedbar
  #   And I type "Foo" into the "Find" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I uncheck "Wrap Around" in the speedbar
  #   And I press "Previous" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 8 to 11
  #   When I press "Previous" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 0 to 3
  #   When I press "Previous" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be ""
  #   And the selection range should be from 0 to 0
  #
  # Scenario: Find with regular expression
  #   When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
  #   And I move the cursor to 0
  #   And I open the find and replace speedbar
  #   And I type "Fo." into the "Find" field in the speedbar
  #   And I choose "Regex" in the "query_type" field in the speedbar
  #   And I check "Wrap Around" in the speedbar
  #   And I press "Next" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 0 to 3
  #   When I press "Next" in the speedbar
  #   Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
  #   And the selected text should be "Foo"
  #   And the selection range should be from 8 to 11
  #
  # Scenario: Replace and find with no initial selection
  #   When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
  #   And I move the cursor to 0
  #   And I open the find and replace speedbar
  #   And I type "Rab" into the "Find" field in the speedbar
  #   And I type "RABBIT" into the "Replace" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I check "Wrap Around" in the speedbar
  #   And I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 12 to 15
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 19 to 22
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 30 to 33
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
  #   And the selected text should be "RAB"
  #   And the selection range should be from 12 to 15
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
  #   And the selected text should be "RAB"
  #   And the selection range should be from 22 to 25
  #
  # Scenario: Replace and find with matching initial selection
  #   When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
  #   And I select from 12 to 15
  #   And I open the find and replace speedbar
  #   And I type "Rab" into the "Find" field in the speedbar
  #   And I type "RABBIT" into the "Replace" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I check "Wrap Around" in the speedbar
  #   And I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 19 to 22
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 30 to 33
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
  #   And the selected text should be "RAB"
  #   And the selection range should be from 12 to 15
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
  #   And the selected text should be "RAB"
  #   And the selection range should be from 22 to 25
  #
  # Scenario: Replace and find with initial selection that doesn't match
  #   When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
  #   And I select from 4 to 7
  #   And I open the find and replace speedbar
  #   And I type "Rab" into the "Find" field in the speedbar
  #   And I type "RABBIT" into the "Replace" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I check "Wrap Around" in the speedbar
  #   And I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 12 to 15
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 19 to 22
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 30 to 33
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
  #   And the selected text should be "RAB"
  #   And the selection range should be from 12 to 15
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
  #   And the selected text should be "RAB"
  #   And the selection range should be from 22 to 25
  #
  # Scenario: Replace and find with initial selection that is after last match
  #   When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
  #   And I select from 28 to 31
  #   And I open the find and replace speedbar
  #   And I type "Rab" into the "Find" field in the speedbar
  #   And I type "RABBIT" into the "Replace" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I check "Wrap Around" in the speedbar
  #   And I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 12 to 15
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 19 to 22
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 30 to 33
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
  #   And the selected text should be "RAB"
  #   And the selection range should be from 12 to 15
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
  #   And the selected text should be "RAB"
  #   And the selection range should be from 22 to 25
  #
  # Scenario: Replace and find with initial selection that is after last match and no wrap around
  #   When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
  #   And I select from 28 to 31
  #   And I open the find and replace speedbar
  #   And I type "Rab" into the "Find" field in the speedbar
  #   And I type "RABBIT" into the "Replace" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I uncheck "Wrap Around" in the speedbar
  #   And I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be ""
  #   And the selection range should be from 31 to 31
  #   When I press "Replace && Find" in the speedbar
  #   Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
  #   And the selected text should be ""
  #   And the selection range should be from 31 to 31
  #
  # Scenario: Replace all replaces one
  #   When I replace the contents with "Foo\nBar\nBaz"
  #   And I move the cursor to 0
  #   And I open the find and replace speedbar
  #   And I type "Bar" into the "Find" field in the speedbar
  #   And I type "Rab" into the "Replace" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I uncheck "Wrap Around" in the speedbar
  #   And I press "Replace All" in the speedbar
  #   Then the contents should be "Foo\nRab\nBaz"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 4 to 7
  #
  # Scenario: Replace all replaces two
  #   When I replace the contents with "Foo\nBar\nBaz\nBar\nQux"
  #   And I move the cursor to 0
  #   And I open the find and replace speedbar
  #   And I type "Bar" into the "Find" field in the speedbar
  #   And I type "Rab" into the "Replace" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I uncheck "Wrap Around" in the speedbar
  #   And I press "Replace All" in the speedbar
  #   Then the contents should be "Foo\nRab\nBaz\nRab\nQux"
  #   And the selected text should be "Rab"
  #   And the selection range should be from 12 to 15
  #
  # Scenario: Replace all replaces two on the same line
  #   When I replace the contents with "abcabc"
  #   And I open the find and replace speedbar
  #   And I type "bc" into the "Find" field in the speedbar
  #   And I type "xx" into the "Replace" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I uncheck "Wrap Around" in the speedbar
  #   And I press "Replace All" in the speedbar
  #   Then the contents should be "axxaxx"
  #   And the selected text should be "xx"
  #   And the selection range should be from 4 to 6
  #   When I press "Replace All" in the speedbar
  #   Then the contents should be "axxaxx"
  #   And the selected text should be "xx"
  #   And the selection range should be from 4 to 6
  #
  # Scenario: Replace all replaces overlapping occurences on the same line
  #   When I replace the contents with "deedeedeed"
  #   And I open the find and replace speedbar
  #   And I type "deed" into the "Find" field in the speedbar
  #   And I type "misdeed" into the "Replace" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I uncheck "Wrap Around" in the speedbar
  #   And I press "Replace All" in the speedbar
  #   Then the contents should be "misdeedeemisdeed"
  #   And the selected text should be "misdeed"
  #   And the selection range should be from 9 to 16
  #
  # Scenario: Replace all is a single undo action
  #   When I replace the contents with "Foo\n\nabcabc\n\nBar"
  #   And I open the find and replace speedbar
  #   And I type "bc" into the "Find" field in the speedbar
  #   And I type "xx" into the "Replace" field in the speedbar
  #   And I choose "Plain" in the "query_type" field in the speedbar
  #   And I uncheck "Wrap Around" in the speedbar
  #   And I press "Replace All" in the speedbar
  #   Then the contents should be "Foo\n\naxxaxx\n\nBar"
  #   And the selected text should be "xx"
  #   And the selection range should be from 9 to 11
  #   When I undo
  #   Then the contents should be "Foo\n\nabcabc\n\nBar"
  #
  # Scenario: Replace all regex with back-references
  #   When I replace the contents with "One fish\ntwo fish\nred fish\nblue fish"
  #   And I move the cursor to 0
  #   And I open the find and replace speedbar
  #   And I type "(\w+) fish" into the "Find" field in the speedbar
  #   And I type "\1 car" into the "Replace" field in the speedbar
  #   And I choose "Regex" in the "query_type" field in the speedbar
  #   And I uncheck "Wrap Around" in the speedbar
  #   And I press "Replace All" in the speedbar
  #   Then the contents should be "One car\ntwo car\nred car\nblue car"
  #   And the selected text should be "blue car"
  #   And the selection range should be from 24 to 32

  # TODO: Scenarios with match case
  # TODO: Scenarios with glob search type
