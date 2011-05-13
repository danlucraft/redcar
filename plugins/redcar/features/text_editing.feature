
Feature: Text editing commands

  Background:
    Given I open a new edit tab

  Scenario: Delete char
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::DeleteCharCommand
    Then the cursor should be at 0
    And the contents should be "oo\nBar\nBaz"

  Scenario: Delete char at end of document
    When I replace the contents with "Foo"
    And I move the cursor to 3
    And I run the command Redcar::Top::DeleteCharCommand
    Then the cursor should be at 3
    And the contents should be "Foo"

  Scenario: Backspace
    When I replace the contents with "Foo"
    And I move the cursor to 1
    And I run the command Redcar::Top::BackspaceCommand
    Then the cursor should be at 0
    And the contents should be "oo"

  Scenario: Backspace at start of document
    When I replace the contents with "Foo"
    And I move the cursor to 0
    And I run the command Redcar::Top::BackspaceCommand
    Then the cursor should be at 0
    And the contents should be "Foo"

