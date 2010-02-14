Feature: Soft and hard tabs
  
  Scenario: Inserts hard tab at the start of a line
    When I open a new edit tab
    And tabs are hard
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "\t"
    
  Scenario: Inserts hard tab at the end of a line
    When I open a new edit tab
    And tabs are hard
    And I replace the contents with "Hacker"
    And I move the cursor to 6
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "Hacker\t"
    
  Scenario: Inserts 2 space soft tab at the start of a line
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "  "
    
  Scenario: Inserts 2 space soft tab at the end of a line
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I replace the contents with "Hacker"
    And I move the cursor to 6
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "Hacker  "
    
  Scenario: Inserts 4 space soft tab at the start of a line
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "    "
    
  Scenario: Inserts 4 space soft tab at the end of a line
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Hacker"
    And I move the cursor to 6
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "Hacker  "
     