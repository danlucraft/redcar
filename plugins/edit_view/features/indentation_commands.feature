Feature: Indentation commands

  Scenario: Increase indent, soft tabs, width 2
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I run the command Redcar::Top::IncreaseIndentCommand
    Then the contents should be "  "
    
  Scenario: Decrease indent, soft tabs, width 2
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I replace the contents with "<c>    "
    And I run the command Redcar::Top::DecreaseIndentCommand
    Then the contents should be "  "

  Scenario: Increase indent, soft tabs, width 3
    When I open a new edit tab
    And tabs are soft, 3 spaces
    And I run the command Redcar::Top::IncreaseIndentCommand
    Then the contents should be "   "
    
  Scenario: Decrease indent, soft tabs, width 3
    When I open a new edit tab
    And tabs are soft, 3 spaces
    And I replace the contents with "<c>      "
    And I run the command Redcar::Top::DecreaseIndentCommand
    Then the contents should be "   "

  Scenario: Increase indent, hard tabs, width 2
    When I open a new edit tab
    And tabs are hard
    And I run the command Redcar::Top::IncreaseIndentCommand
    Then the contents should be "\t"
    
  Scenario: Decrease indent, hard tabs, width 2
    When I open a new edit tab
    And tabs are hard
    And I replace the contents with "<c>\t\t"
    And I run the command Redcar::Top::DecreaseIndentCommand
    Then the contents should be "\t"
    
  Scenario: auto-indent, soft tabs, width 2
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I replace the contents with "def f\n\t1\t\t\nend\t"
    And I select from 0 to 13
    And I run the command Redcar::AutoIndenter::IndentCommand
    Then the contents should be "def f\n  1\nend"
