
@speedbar
Feature: Goto line command

  Background:
    Given I open a new edit tab

  Scenario: Open goto line speedbar
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::GotoLineCommand
    Then the Redcar::Top::GotoLineCommand::Speedbar speedbar should be open

  Scenario: Search for a word should select next occurrence
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::GotoLineCommand
    And I type "2" into the "line" field in the speedbar
    And I press "Go" in the speedbar
    Then the cursor should be on line 1
