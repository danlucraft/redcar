
@speedbar
Feature: Replace in file

  Background:
    Given I open a new edit tab

  Scenario: Open replace speedbar
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    Then the DocumentSearch::SearchAndReplaceSpeedbar speedbar should be open

  Scenario: Replace next occurrence on the same line
    When I replace the contents with "Foo\nBar Rab Rab\nBaz"
    And I move the cursor to 4
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "Rab" into the "Search" field in the speedbar
    And I type "RABBIT" into the "Replace" field in the speedbar
    And I press "Replace" in the speedbar
    Then the contents should be "Foo\nBar RABBIT Rab\nBaz"
    And the selected text should be "RABBIT"
    And the selection range should be from 8 to 14 

  Scenario: Replace next occurrence on the same line twice
    When I replace the contents with "Foo\nBar Rab Rab\nBaz"
    And I move the cursor to 4
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "Rab" into the "Search" field in the speedbar
    And I type "RAB" into the "Replace" field in the speedbar
    And I press "Replace" in the speedbar
    And I press "Replace" in the speedbar
    Then the contents should be "Foo\nBar RAB RAB\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 12 to 15

  Scenario: Replace next occurrence
    When I replace the contents with "Foo\nBar\nBaz\nBar\nQux"
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "Bar" into the "Search" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    And I press "Replace" in the speedbar
    Then the contents should be "Foo\nRab\nBaz\nBar\nQux"
    And the selected text should be "Rab"
    And the selection should be on line 1

  Scenario: Replace next occurrence twice
    When I replace the contents with "Foo\nBar\nBaz\nBar\nQux"
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "Bar" into the "Search" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    And I press "Replace" in the speedbar
    Then the contents should be "Foo\nRab\nBaz\nBar\nQux"
    When I press "Replace" in the speedbar
    Then the contents should be "Foo\nRab\nBaz\nRab\nQux"
    And the selected text should be "Rab"
    And the selection should be on line 3

  Scenario: Replace next occurrence wraps
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 8
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "Bar" into the "Search" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    When I press "Replace" in the speedbar
    Then the contents should be "Foo\nRab\nBaz"
    And the selected text should be "Rab"

  Scenario: Replace all replaces one
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "Bar" into the "Search" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    Then I should see a message box containing "Replaced 1 occurrence"
    When I press "Replace All" in the speedbar
    Then the contents should be "Foo\nRab\nBaz"
    And the selected text should be "Rab"
    And the selection should be on line 1

  Scenario: Replace all replaces two
    When I replace the contents with "Foo\nBar\nBaz\nBar\nQux"
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "Bar" into the "Search" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    Then I should see a message box containing "Replaced 2 occurrences"
    When I press "Replace All" in the speedbar
    Then the contents should be "Foo\nRab\nBaz\nRab\nQux"
    And the selected text should be "Rab"
    And the selection should be on line 3

  Scenario: Replace all replaces two on the same line
    When I replace the contents with "abcabc"
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "bc" into the "Search" field in the speedbar
    And I type "xx" into the "Replace" field in the speedbar
    Then I should see a message box containing "Replaced 2 occurrences"
    When I press "Replace All" in the speedbar
    Then the contents should be "axxaxx"

  Scenario: Replace all replaces overlapping occurences on the same line
    When I replace the contents with "deedeedeed"
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "deed" into the "Search" field in the speedbar
    And I type "misdeed" into the "Replace" field in the speedbar
    Then I should see a message box containing "Replaced 2 occurrences"
    When I press "Replace All" in the speedbar
    Then the contents should be "misdeedeemisdeed"

  Scenario: Replace next occurrence test bug
    When I replace the contents with "the\n* Speedbars have access to the properties of the widgets in them."
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "the" into the "Search" field in the speedbar
    And I type "THE" into the "Replace" field in the speedbar
    And I press "Replace" in the speedbar
    Then the contents should be "THE\n* Speedbars have access to the properties of the widgets in them."
    And the selection range should be from 0 to 3
    And I press "Replace" in the speedbar
    Then the contents should be "THE\n* Speedbars have access to THE properties of the widgets in them."
    And the selection range should be from 31 to 34
    And I press "Replace" in the speedbar
    Then the contents should be "THE\n* Speedbars have access to THE properties of THE widgets in them."
    And the selection range should be from 49 to 52
    And I press "Replace" in the speedbar
    Then the contents should be "THE\n* Speedbars have access to THE properties of THE widgets in THEm."
    And the selection range should be from 64 to 67

  Scenario: Replace regex with back-references
    When I replace the contents with "Curry chicken"
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "(\w+) chicken" into the "Search" field in the speedbar
    And I type "\1 beef" into the "Replace" field in the speedbar
    And I press "Replace" in the speedbar
    Then the contents should be "Curry beef"

  Scenario: Replace should move past the current replacement if the query is a substring of the replacement
    When I replace the contents with "foo\nfoo\nfoo"
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "foo" into the "Search" field in the speedbar
    And I type "foobar" into the "Replace" field in the speedbar
    And I press "Replace" in the speedbar
    And I press "Replace" in the speedbar
    And I press "Replace" in the speedbar
    Then the contents should be "foobar\nfoobar\nfoobar"
    And the selection range should be from 14 to 20

  Scenario: The Search-and-Replace Speedbar should get initialized with the currently selected text
    When I replace the contents with "Foo\nBar\nFoo"
    And I select from 4 to 7
    When I run the command DocumentSearch::SearchAndReplaceCommand
    Then the "Search" field in the speedbar should have text "Bar"
    When I type "Foo" into the "Replace" field in the speedbar
    And I press "Replace" in the speedbar
    Then the contents should be "Foo\nFoo\nFoo"

  