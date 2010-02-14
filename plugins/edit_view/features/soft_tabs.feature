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
     
  Scenario: Move left through soft tabs
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I replace the contents with "    "
    And I move the cursor to 4
    And I press the Left key in the edit tab
    Then the cursor should be at 2

  Scenario: Move right through soft tabs
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I replace the contents with "    "
    And I move the cursor to 0
    And I press the Right key in the edit tab
    Then the cursor should be at 2
    
  Scenario: Moves left through part of a soft tab
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Hacker  "
    And I move the cursor to 8
    And I press the Left key in the edit tab
    Then the cursor should be at 6
     
  Scenario: Moves right through part of a soft tab
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Hacker  "
    And I move the cursor to 6
    And I press the Right key in the edit tab
    Then the cursor should be at 8
    
  Scenario: Moves left through spaces that don't make a full tab
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Hacker    "
    And I move the cursor to 10
    Then the Left key in the edit tab should not be handled
  
  Scenario: Moves right through spaces that don't make a full tab
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Hacker    "
    And I move the cursor to 8
    And the Right key in the edit tab should not be handled

  Scenario: Shouldn't die if the cursor is at the start of the document
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with ""
    And I move the cursor to 0
    And I press the Left key in the edit tab
    Then the cursor should be at 0

  Scenario: Shouldn't die if the cursor is at the end of the document
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with ""
    And I move the cursor to 0
    And I press the Right key in the edit tab
    Then the cursor should be at 0
  
 