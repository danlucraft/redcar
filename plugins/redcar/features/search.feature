
@speedbar
Feature: Search in file

  Background:
    Given I open a new edit tab

  Scenario: Open search speedbar
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::SearchForwardCommand
    Then the Redcar::Top::SearchForwardCommand::SearchSpeedbar speedbar should be open

  Scenario: Search for a word should select next occurrence
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::SearchForwardCommand
    And I type "Bar" into the "query" field in the speedbar
    And I press "Search" in the speedbar
    Then the selected text should be "Bar"

  Scenario: Search twice should move to the next occurrence
    When I replace the contents with "Foo\nBar\nFoo"
    And I move the cursor to 0
    And I run the command Redcar::Top::SearchForwardCommand
    And I type "Foo" into the "query" field in the speedbar
    And I press "Search" in the speedbar
    And I press "Search" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 2

  Scenario: Search for a word adjacent to cursor should select word
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::SearchForwardCommand
    And I type "Foo" into the "query" field in the speedbar
    And I press "Search" in the speedbar
    Then the selected text should be "Foo"

  Scenario: Search for a word should find occurrence after the cursor
    When I replace the contents with "Foo\nBar\nBaz\nFoo"
    And I move the cursor to 1
    And I run the command Redcar::Top::SearchForwardCommand
    And I type "Foo" into the "query" field in the speedbar
    And I press "Search" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 3

  Scenario: Search for a word should wrap to earlier occurrence if none left
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 1
    And I run the command Redcar::Top::SearchForwardCommand
    And I type "Foo" into the "query" field in the speedbar
    And I press "Search" in the speedbar
    Then the selected text should be "Foo"
    And the selection should be on line 0

  Scenario: Doesn't search for a regex by default
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::SearchForwardCommand
    And I type "Ba." into the "query" field in the speedbar
    And I press "Search" in the speedbar
    Then there should not be any text selected
  
  Scenario: Search for a regex
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::SearchForwardCommand
    And I type "Ba." into the "query" field in the speedbar
    And I check "Regex" in the speedbar
    And I press "Search" in the speedbar
    Then the selected text should be "Bar"
  
  Scenario: Search for a regex matches a second time
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::SearchForwardCommand
    And I type "Ba." into the "query" field in the speedbar
    And I check "Regex" in the speedbar
    And I press "Search" in the speedbar
    And I press "Search" in the speedbar
    Then the selected text should be "Baz"
  
  Scenario: Should not match case by default
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::SearchForwardCommand
    And I type "foo" into the "query" field in the speedbar
    And I press "Search" in the speedbar
    Then the selected text should be "Foo"

  Scenario: Should match case if requested
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::SearchForwardCommand
    And I type "foo" into the "query" field in the speedbar
    And I check "Match case" in the speedbar
    And I press "Search" in the speedbar
    Then there should not be any text selected

  Scenario: Should scroll to the match
    When I replace the contents with 100 lines of "xxx" then "Foo"
    And I scroll to the top of the document
    And I move the cursor to 0
    And I run the command Redcar::Top::SearchForwardCommand
    And I type "Foo" into the "query" field in the speedbar
    And I press "Search" in the speedbar
    Then the selected text should be "Foo"
    And line number 100 should be visible

