Feature: Automatically insert paired characters
  # This isn't a proper test because I haven't found a way to simulate
  # a keypress so that text is inserted and the cursor moves. Therefore these
  # tests assume that the cursor may be in the wrong place at any moment.

  Scenario: Inserts quote marks
    When I open a new edit tab
    And I insert "\"" at the cursor
    Then the contents should be "\"\""
    
  Scenario: Inserts parentheses
    When I open a new edit tab
    And I insert "(" at the cursor
    Then the contents should be "()"
    
  Scenario: Delete start character (quotes)
    When I open a new edit tab
    And I insert "\"" at the cursor
    And I move the cursor to 1
    And I press the Backspace key in the edit tab
    Then the contents should be ""

  Scenario: Delete start character (parentheses)
    When I open a new edit tab
    And I insert "(" at the cursor
    And I move the cursor to 1
    And I press the Backspace key in the edit tab
    Then the contents should be ""

  Scenario: Type over ends
    When I open a new edit tab
    And I insert "(" at the cursor
    And I move the cursor to 1
    And I insert ")" at the cursor
    Then the contents should be "()"
  
  Scenario: Wrap selected text
    When I open a new edit tab
    And I insert "Boris" at the cursor
    And I select from 0 to 5
    And I replace 0 to 5 with "("
    Then the contents should be "(Boris)"

  Scenario: Inserts ending character nested
    When I open a new edit tab
    And I insert "\"" at 0
    And I insert "(" at 1
    Then the contents should be "\"()\""
    
  Scenario: Delete start character nested
    When I open a new edit tab
    And I insert "\"" at 0
    And I insert "(" at 1
    And I move the cursor to 2
    And I press the Backspace key in the edit tab
    Then the contents should be "\"\""
    And I move the cursor to 1
    And I press the Backspace key in the edit tab
    Then the contents should be ""

  Scenario: Type over ends nested
    When I open a new edit tab
    And I insert "(" at 0
    And I insert "\"" at 1
    And I insert "\"" at 2
    And I insert ")" at 3
    Then the contents should be "(\"\")"
  
  Scenario: Don't delete start character if moved away
    When I open a new edit tab
    And I replace the contents with "0123456789"
    And I insert "(" at 0
    And I move the cursor to 5
    And I move the cursor to 1
    And I press the Backspace key in the edit tab
    Then the contents should be ")0123456789"

  Scenario: Don't type over end if moved away
    When I open a new edit tab
    And I replace the contents with "0123456789"
    And I insert "(" at 0
    And I move the cursor to 5
    And I insert ")" at 1
    Then the contents should be "())0123456789"

  
  