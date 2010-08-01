
@speedbar
Feature: Replace in file

  Background:
    Given I open a new edit tab

  Scenario: Open replace speedbar
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    Then the DocumentSearch::SearchAndReplaceSpeedbar speedbar should be open

  Scenario: Replace next occurrence
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "Bar" into the "Search" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    And I press "Replace" in the speedbar
    Then the contents should be "Foo\nRab\nBaz"

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

  Scenario: Replace all replaces one
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "Bar" into the "Search" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    Then I should see a message box containing "Replaced 1 occurrence"
    When I press "Replace All" in the speedbar
    Then the contents should be "Foo\nRab\nBaz"

  Scenario: Replace all replaces two
    When I replace the contents with "Foo\nBar\nBaz\nBar\nQux"
    And I move the cursor to 0
    And I run the command DocumentSearch::SearchAndReplaceCommand
    And I type "Bar" into the "Search" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    Then I should see a message box containing "Replaced 2 occurrences"
    When I press "Replace All" in the speedbar
    Then the contents should be "Foo\nRab\nBaz\nRab\nQux"
