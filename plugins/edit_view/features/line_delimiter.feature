Feature: Line delimiter

  Scenario: Chooses line delimiter by text put in the tab (Windows)
    When I open a new edit tab
    And I replace the contents with "foo\r\nbar\r\nbaz\r\n"
    Then the line delimiter should be "\r\n"

  Scenario: Delete at end of line deletes delimiter (Windows)
    When I open a new edit tab
    And I replace the contents with "foo\r\nbar\r\nbaz\r\n"
    And I move the cursor to 3
    And I press the Delete key in the edit tab
    Then the contents should be "foobar\r\nbaz\r\n"
    
  Scenario: Backspace at start of line deletes delimiter (Windows)
    When I open a new edit tab
    And I replace the contents with "foo\r\nbar\r\nbaz\r\n"
    And I move the cursor to 5
    And I press the Backspace key in the edit tab
    Then the contents should be "foobar\r\nbaz\r\n"
    
  Scenario: Chooses line delimiter by text put in the tab (Unix)
    When I open a new edit tab
    And I replace the contents with "foo\nbar\nbaz\n"
    Then the line delimiter should be "\n"

  Scenario: Delete at end of line deletes delimiter (Unix)
    When I open a new edit tab
    And I replace the contents with "foo\nbar\nbaz\n"
    And I move the cursor to 3
    And I press the Delete key in the edit tab
    Then the contents should be "foobar\nbaz\n"
    
  Scenario: Backspace at start of line deletes delimiter (Windows)
    When I open a new edit tab
    And I replace the contents with "foo\nbar\nbaz\n"
    And I move the cursor to 4
    And I press the Backspace key in the edit tab
    Then the contents should be "foobar\nbaz\n"
    
  Scenario: End goes to end of line (Windows)
    When I open a new edit tab
    And I replace the contents with "foo\r\nbar\r\nbaz\r\n"
    And I move the cursor to 0
    And I run the command Redcar::Top::MoveEndCommand
    Then the cursor should be at 3
    