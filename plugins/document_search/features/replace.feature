
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
    And I type "RAB" into the "Replace" field in the speedbar
    And I press "Replace" in the speedbar
    Then the contents should be "Foo\nBar RAB Rab\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 8 to 11 

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

  