@speedbar
Feature: Find

  Background:
    Given I open a new edit tab

  # Begin: Scenarios adapted from incremental_search.feature

  Scenario: Open Find speedbar
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    Then I should see the find speedbar

  Scenario: Search for a word should select next occurrence
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Bar" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Bar"

  Scenario: Search twice should move to the next occurrence
    When I replace the contents with "Foo\nBar\nFoo"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selection should be on line 0
    When I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 2

  Scenario: Search for a word adjacent to cursor should select word
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"

  Scenario: Search for a word should find occurrence after the cursor
    When I replace the contents with "Foo\nBar\nBaz\nFoo"
    And I move the cursor to 1
    And I open the find speedbar
    And I type "Foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selection should be on line 3
    And the selected text should be "Foo"
    When I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0

  Scenario: Search for a word should wrap to earlier occurrence if none left
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 3
    And I open the find speedbar
    And I type "Foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0

  Scenario: Should start searching after the selection if the query matches exactly
    When I replace the contents with "Foobar\nBarfoo\nBazhmm\nFoobar"
    And I select from 0 to 6
    And I open the find speedbar
    And I type "Foobar" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foobar"
    And the selection should be on line 3

  Scenario: Should start search within the selection if it matches the beginning of the query
    When I replace the contents with "Foobar\nBarfoo\nBazhmm\nFoobar"
    And I select from 0 to 3
    And I open the find speedbar
    And I type "Foobar" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foobar"
    And the selection range should be from 0 to 6

  Scenario: Should start search within the selection if the query matches partially
    When I replace the contents with "Foobar\nBarfoo\nBazhmm\nFoobar"
    And I select from 0 to 6
    And I open the find speedbar
    And I type "Foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection range should be from 0 to 3

  Scenario: Not thrown off by multi-byte characters
    When I replace the contents with "Benedikt Müller"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "ler" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "ler"
    And the selection range should be from 12 to 15

  Scenario: Not thrown off by multi-byte characters 2
    When I replace the contents with "Benedikt Müller\n foo "
    And I move the cursor to 0
    And I open the find speedbar
    And I type "foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "foo"
    And the selection range should be from 17 to 20

  Scenario: Not thrown off by multi-byte characters 3
    When I replace the contents with "你好, 凯兰\nYou make my heart super happy."
    And I move the cursor to 0
    And I open the find speedbar
    And I type "you" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "You"
    And the selection range should be from 7 to 10

  Scenario: Handles repeated search across by multi-byte characters
    When I replace the contents with "Foo\n你好, 凯兰\nFoo\nBar\nFoo\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0
    When I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 2
    When I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 4
    When I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0
    When I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 2

  Scenario: Should select multi-byte characters
    When I replace the contents with "Benedikt Müller"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "mül" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Mül"
    And the selection range should be from 9 to 12

  Scenario: Should select multi-byte characters
    When I replace the contents with "Benedikt Müller"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "mül" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Mül"
    And the selection range should be from 9 to 12

  Scenario: Should select multi-byte characters 2
    When I replace the contents with "你好, 凯兰\nYou make my heart super happy."
    And I move the cursor to 0
    And I open the find speedbar
    And I type "凯兰" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "凯兰"
    And the selection range should be from 4 to 6

  Scenario: Doesn't search for a regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Ba." into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then there should not be any text selected

  Scenario: Search for a regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Ba." into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then there should not be any text selected
    When I check "Regex" in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Bar"
    When I press "Next" in the speedbar
    Then the selected text should be "Baz"

  Scenario: Should not match case by default
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should not match case with regex by default
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "fo." into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then there should not be any text selected
    When I check "Regex" in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should match case if requested
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"
    When I check "Match case" in the speedbar
    And I move the cursor to 0
    And I press "Next" in the speedbar
    Then there should not be any text selected
    When I type "Foo" into the "Find" field in the speedbar
    And I move the cursor to 0
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should match case if requested with regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I check "Regex" in the speedbar
    And I type "fo." into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"
    When I check "Match case" in the speedbar
    And I move the cursor to 0
    And I press "Next" in the speedbar
    Then there should not be any text selected

  Scenario: Find next with wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
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
    And I open the find speedbar
    And I uncheck "Wrap around" in the speedbar
    And I type "foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
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

  Scenario: Find previous with wrap around by default
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 18
    And I open the find speedbar
    And I type "foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I press "Previous" in the speedbar
    Then the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I press "Previous" in the speedbar
    Then the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I press "Previous" in the speedbar
    Then the selected text should be "Foo"
    And the selection range should be from 8 to 11

  Scenario: Find previous without wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 18
    And I open the find speedbar
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
    And I type "foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And line number 100 should be visible

  Scenario: "Should scroll horizontally to the match"
    When I replace the contents with 300 "x" then "Foo"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "foo" into the "Find" field in the speedbar
    And I press "Next" in the speedbar
    Then the selected text should be "Foo"
    And horizontal offset 302 should be visible

  Scenario: Should reopen with the same text as the previous search
    When I open the find speedbar
    And I type "foo" into the "Find" field in the speedbar
    And I close the speedbar
    And I open the find speedbar
    Then the "Find" field in the speedbar should have text "foo"

  Scenario: Should initialize query with the currently selected text
    When I replace the contents with "Flux\nBar\nFoo"
    And I move the cursor to 0
    And I select from 0 to 4
    And I open the find speedbar
    Then the "Find" field in the speedbar should have text "Flux"

  # End: Scenarios adapted from incremental_search.feature

  # Begin: Replacement scenarios specific to Find speedbar

  Scenario: Replace and find with no initial selection
    When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Rab" into the "Find" field in the speedbar
    And I type "RABBIT" into the "Replace" field in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 19 to 22
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 30 to 33
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 22 to 25

  Scenario: Replace and find with matching initial selection
    When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And I select from 12 to 15
    And I open the find speedbar
    And I type "Rab" into the "Find" field in the speedbar
    And I type "RABBIT" into the "Replace" field in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 19 to 22
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 30 to 33
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 22 to 25

  Scenario: Replace and find with initial selection that doesn't match
    When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And I select from 4 to 7
    And I open the find speedbar
    And I type "Rab" into the "Find" field in the speedbar
    And I type "RABBIT" into the "Replace" field in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 19 to 22
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 30 to 33
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 22 to 25

  Scenario: Replace and find with initial selection that is after last match
    When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And I select from 28 to 31
    And I open the find speedbar
    And I type "Rab" into the "Find" field in the speedbar
    And I type "RABBIT" into the "Replace" field in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 19 to 22
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 30 to 33
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 22 to 25

  Scenario: Replace and find with initial selection that is after last match and no wrap around
    When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And I select from 28 to 31
    And I open the find speedbar
    And I type "Rab" into the "Find" field in the speedbar
    And I type "RABBIT" into the "Replace" field in the speedbar
    And I uncheck "Wrap around" in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be ""
    And the selection range should be from 31 to 31
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be ""
    And the selection range should be from 31 to 31

  Scenario: Replace all replaces one
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Bar" into the "Find" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    And I uncheck "Wrap around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "Foo\nRab\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 4 to 7

  Scenario: Replace all replaces two
    When I replace the contents with "Foo\nBar\nBaz\nBar\nQux"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "Bar" into the "Find" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    And I uncheck "Wrap around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "Foo\nRab\nBaz\nRab\nQux"
    And the selected text should be "Rab"
    And the selection range should be from 12 to 15

  Scenario: Replace all replaces two on the same line
    When I replace the contents with "abcabc"
    And I open the find speedbar
    And I type "bc" into the "Find" field in the speedbar
    And I type "xx" into the "Replace" field in the speedbar
    And I uncheck "Wrap around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "axxaxx"
    And the selected text should be "xx"
    And the selection range should be from 4 to 6
    When I press "Replace All" in the speedbar
    Then the contents should be "axxaxx"
    And the selected text should be "xx"
    And the selection range should be from 4 to 6

  Scenario: Replace all replaces overlapping occurences on the same line
    When I replace the contents with "deedeedeed"
    And I open the find speedbar
    And I type "deed" into the "Find" field in the speedbar
    And I type "misdeed" into the "Replace" field in the speedbar
    And I uncheck "Wrap around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "misdeedeemisdeed"
    And the selected text should be "misdeed"
    And the selection range should be from 9 to 16

  Scenario: Replace all is a single undo action
    When I replace the contents with "Foo\n\nabcabc\n\nBar"
    And I open the find speedbar
    And I type "bc" into the "Find" field in the speedbar
    And I type "xx" into the "Replace" field in the speedbar
    And I uncheck "Wrap around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "Foo\n\naxxaxx\n\nBar"
    And the selected text should be "xx"
    And the selection range should be from 9 to 11
    When I undo
    Then the contents should be "Foo\n\nabcabc\n\nBar"

  Scenario: Replace all regex with back-references
    When I replace the contents with "One fish\ntwo fish\nred fish\nblue fish"
    And I move the cursor to 0
    And I open the find speedbar
    And I type "(\w+) fish" into the "Find" field in the speedbar
    And I type "\1 car" into the "Replace" field in the speedbar
    And I check "Regex" in the speedbar
    And I uncheck "Wrap around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "One car\ntwo car\nred car\nblue car"
    And the selected text should be "blue car"
    And the selection range should be from 24 to 32

  # End: Replacement scenarios specific to Find speedbar
