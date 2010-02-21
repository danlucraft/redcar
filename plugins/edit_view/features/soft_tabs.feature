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

  Scenario: Inserts 4 space soft tab at the end of a line, with a tab character
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "\tHacker"
    And I move the cursor to 7
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "\tHacker  "
     
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
    And I press the Left key in the edit tab
    Then the cursor should be at 9
  
  Scenario: Moves right through spaces that don't make a full tab
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Hacker    "
    And I move the cursor to 8
    And I press the Right key in the edit tab
    Then the cursor should be at 9

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
  
  Scenario: Move left through soft tabs, with a tab character
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "\tHa    "
    And I move the cursor to 1
    And I press the Left key in the edit tab
    Then the cursor should be at 0

  Scenario: Move left through soft tabs 2, with a tab character
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "\tHa    "
    And I move the cursor to 2
    And I press the Left key in the edit tab
    Then the cursor should be at 1

  Scenario: Move left through soft tabs 2, with a tab character
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "\tHa    "
    And I move the cursor to 4
    And I press the Left key in the edit tab
    Then the cursor should be at 3

  Scenario: Move left through soft tabs 3, with a tab character
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "\tHa    "
    And I move the cursor to 5
    And I press the Left key in the edit tab
    Then the cursor should be at 3

  Scenario: Move left through soft tabs 4, with a tab character
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "\tHa    "
    And I move the cursor to 6
    And I press the Left key in the edit tab
    Then the cursor should be at 5
  
  Scenario: Move right through soft tabs, with a tab character
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "\tHa    "
    And I move the cursor to 0
    And I press the Right key in the edit tab
    Then the cursor should be at 1

  Scenario: Move right through soft tabs 2, with a tab character
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "\tHa    "
    And I move the cursor to 1
    And I press the Right key in the edit tab
    Then the cursor should be at 2

  Scenario: Move right through soft tabs 2, with a tab character
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "\tHa    "
    And I move the cursor to 3
    And I press the Right key in the edit tab
    Then the cursor should be at 5

  Scenario: Move right through soft tabs 3, with a tab character
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "\tHa    "
    And I move the cursor to 5
    And I press the Right key in the edit tab
    Then the cursor should be at 6

  Scenario: Move left through soft tabs, with a tab character ahead
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "    Wo\t"
    And I move the cursor to 4
    And I press the Left key in the edit tab
    Then the cursor should be at 0
    
  Scenario: Select left through soft tabs
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I replace the contents with "    "
    And I move the cursor to 4
    And I press Shift+Left key in the edit tab
    Then the contents should be "  <c>  <s>"

  Scenario: Select right through soft tabs
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I replace the contents with "    "
    And I move the cursor to 2
    And I press Shift+Right key in the edit tab
    Then the contents should be "  <s>  <c>"
    
  Scenario: Select left twice through soft tabs
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I replace the contents with "    "
    And I move the cursor to 4
    And I press Shift+Left key in the edit tab
    And I press Shift+Left key in the edit tab
    Then the contents should be "<c>    <s>"
    
  Scenario: Select right through soft tabs
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I replace the contents with "    "
    And I move the cursor to 0
    And I press Shift+Right key in the edit tab
    And I press Shift+Right key in the edit tab
    Then the contents should be "<s>    <c>"

  Scenario: Shouldn't die if the cursor is at the start of the document
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with ""
    And I move the cursor to 0
    And I press Shift+Left key in the edit tab
    Then the cursor should be at 0
    
  Scenario: Shouldn't die if the cursor is at the end of the document
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with ""
    And I move the cursor to 0
    And I press Shift+Right key in the edit tab
    Then the cursor should be at 0
  
  Scenario: Can backspace a soft tab
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "    "
    And I move the cursor to 4
    And I press the Backspace key in the edit tab
    Then the contents should be "<c>"
    
  Scenario: Can backspace part of a soft tab
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Ha  "
    And I move the cursor to 4
    And I press the Backspace key in the edit tab
    Then the contents should be "Ha<c>"

  Scenario: Can delete a soft tab
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "    "
    And I move the cursor to 0
    And I press the Delete key in the edit tab
    Then the contents should be "<c>"
    
  Scenario: Can delete part of a soft tab
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Ha  "
    And I move the cursor to 2
    And I press the Delete key in the edit tab
    Then the contents should be "Ha<c>"
    
  Scenario: Move left at the start of a line
    When I open a new edit tab
    And I replace the contents with "Hi\nHo"
    And I move the cursor to 3
    And I press the Left key in the edit tab
    Then the contents should be "Hi<c>\nHo"
    
  Scenario: Shouldn't die if the cursor is at the end of the document
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with ""
    And I move the cursor to 0
    And I press the Delete key in the edit tab
    Then the cursor should be at 0
    