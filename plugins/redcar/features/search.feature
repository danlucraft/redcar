
Feature: Search in file

  Scenario: Search
    When I open a new edit tab
    And I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command Redcar::Top::SearchForwardCommand
    Then the Redcar::Top::SearchForwardCommand::SearchSpeedbar speedbar should be open
