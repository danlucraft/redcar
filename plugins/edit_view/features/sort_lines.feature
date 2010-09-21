Feature: Sort Lines
  
  Background:
    When I open a new edit tab
    
  Scenario: Sort Lines sorts the lines in selected region
    When I replace the contents with "3\n2\n1"
    And I select from 0 to 10
    And I run the command Redcar::Top::SortLinesCommand
    Then the contents should be "1\n2\n3"
    
  Scenario: Nothing is sorted when nothing is selected
    When I replace the contents with "3\n2\n1"
    And I run the command Redcar::Top::SortLinesCommand
    Then the contents should be "3\n2\n1"