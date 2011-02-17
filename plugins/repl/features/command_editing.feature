Feature: Navigation and editing keys have special behaviour in a REPL

  Background:
    When I open a new repl
    And I insert "clear" at the cursor
    And I press the return key
    And I insert "x = 4" at the cursor
    When I move the cursor to the end of the document

  Scenario: Backspace does not erase the prompt
    And I press the backspace key
    Then the current command should be "x = "
    When I press the backspace key
    Then the current command should be "x ="
    When I press the backspace key
    Then the current command should be "x "
    When I press the backspace key
    Then the current command should be "x"
    When I press the backspace key
    Then the current command should be blank
    When I press the backspace key
    Then the current command should be blank
    And I should see ">> " in the edit tab

  Scenario: Delete does not erase the prompt
    When I move the cursor to 0
    And I press the delete key
    Then the current command should be "x = 4"
    And I should see ">> " in the edit tab

  Scenario: The home key sets the cursor at the start of the line and after the prompt
    When I press the home key
    Then the cursor should be at 3
    When I replace 3 to 8 with "x = 4\ny = 9"
    And I move the cursor to 11
    And I press the home key
    Then the cursor should be at 9

  Scenario: Left and right arrow keys can be used to navigate the current command
    When I press the left arrow key
    Then the cursor should be at 7
    When I press the left arrow key
    Then the cursor should be at 6
    When I press the left arrow key
    Then the cursor should be at 5
    When I press the right arrow key
    Then the cursor should be at 6

  Scenario: The left arrow key should not go beyond the prompt
    When I press the return key
    And I insert "clear" at the cursor
    And I press the return key
    Then the cursor should be at 3
    When I press the left arrow key
    Then the cursor should be at 3