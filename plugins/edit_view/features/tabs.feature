Feature: Insert a tab

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

  Scenario: Inserts soft tabs correctly if there is selected text
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Ha"
    And I move the cursor to 0
    And I press Shift+Right key in the edit tab
    And I press Shift+Right key in the edit tab
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "    "

  Scenario: Inserts hard tabs correctly if there is selected text
    When I open a new edit tab
    And tabs are hard
    And I replace the contents with "Ha"
    And I move the cursor to 0
    And I press Shift+Right key in the edit tab
    And I press Shift+Right key in the edit tab
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "\t"

  Scenario: Inserts soft tabs correctly if there is selected text that covers a tab
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "H\t"
    And I move the cursor to 0
    And I press Shift+Right key in the edit tab
    And I press Shift+Right key in the edit tab
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "    "

  Scenario: Inserts 4 space soft tab at the end of a line, with a tab character
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "\tHacker"
    And I move the cursor to 7
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "\tHacker  "

  @block_selection
  Scenario: In block selection mode inserts 4 space soft tab on 1 line
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Jim\nHacker"
    And I block select from 0 to 0
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "    Jim\nHacker"
    And the selection range should be from 4 to 4

  @block_selection
  Scenario: In block selection mode inserts 4 space soft tab on 2 lines
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Jim\nHacker"
    And I block select from 0 to 4
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "    Jim\n    Hacker"
    And the selection range should be from 4 to 12

  @block_selection
  Scenario: In block selection mode inserts 4 space soft tab on 3 lines
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Jim\nHacker\nMP"
    And I block select from 0 to 11
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "    Jim\n    Hacker\n    MP"
    And the selection range should be from 4 to 23

  @block_selection
  Scenario: In block selection mode inserts 4 space soft tab overwriting text on 1 line
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Jim\nHacker"
    And I block select from 0 to 2
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "    m\nHacker"
    And the selection range should be from 4 to 4

  @block_selection
  Scenario: In block selection mode inserts 4 space soft tab overwriting text on 2 lines
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Jim\nHacker"
    And I block select from 0 to 6
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "    m\n    cker"
    And the selection range should be from 4 to 10

  @block_selection
  Scenario: In block selection mode inserts 4 space soft tab overwriting text on 3 lines
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "Jim\nHacker\nMP"
    And I block select from 0 to 13
    And I press the Tab key in the edit tab
    Then the contents of the edit tab should be "    m\n    cker\n    "
    And the selection range should be from 4 to 19





