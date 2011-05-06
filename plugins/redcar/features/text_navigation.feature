
Feature: Text navigation commands

  Background:
    Given I open a new edit tab

  Scenario: Move forward char
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::ForwardCharCommand
    Then the cursor should be at 1

  Scenario: Move forward char at end of document
    When I replace the contents with "Foo"
    And I move the cursor to 3
    And I run the command Redcar::Top::ForwardCharCommand
    Then the cursor should be at 3

  Scenario: Move backward char
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 3
    And I run the command Redcar::Top::BackwardCharCommand
    Then the cursor should be at 2

  Scenario: Move backward char at beginning of document
    When I replace the contents with "Foo"
    And I move the cursor to 0
    And I run the command Redcar::Top::BackwardCharCommand
    Then the cursor should be at 0

