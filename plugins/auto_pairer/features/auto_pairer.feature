Feature: Automatically insert paired characters

  Scenario: Inserts quote marks
    When I open a new edit tab
    And I type "\""
    Then the contents should be "\"<c>\""
    
  Scenario: Don't insert quote mark if we're already open
    When I open a new edit tab
    And I replace the contents with "foo \" bár q"
    And I move to the end of the line
    And I move left
    When I type "\""
    Then the contents should be "foo \" bár \"q"
    
  Scenario: Inserts parentheses
    When I open a new edit tab
    And I type "("
    Then the contents should be "(<c>)"
    
  Scenario: Delete start character (quotes)
    When I open a new edit tab
    And I type "\""
    And I backspace
    Then the contents should be ""

  Scenario: Delete start character (parentheses)
    When I open a new edit tab
    And I type "("
    And I backspace
    Then the contents should be ""

  Scenario: Type over ends
    When I open a new edit tab
    And I type "("
    And I type ")"
    Then the contents should be "()<c>"
  
  Scenario: Wrap selected text
    When I open a new edit tab
    And I type "Boris"
    And I select from 0 to 5
    And I type "("
    Then the contents should be "(Boris)<c>"

  Scenario: Inserts ending character nested
    When I open a new edit tab
    And I type "\""
    And I type "("
    Then the contents should be "\"(<c>)\""
    
  Scenario: Delete start character nested
    When I open a new edit tab
    And I type "\""
    And I type "("
    And I backspace
    Then the contents should be "\"<c>\""
    When I backspace
    Then the contents should be ""

  Scenario: Type over ends nested
    When I open a new edit tab
    And I type "("
    And I type "\""
    And I type "\""
    And I type ")"
    Then the contents should be "(\"\")<c>"
  
  Scenario: Don't delete start character if moved away
    When I open a new edit tab
    And I type "0123456789"
    And I move to the start of the line
    And I type "("
    And I move to the end of the line
    And I move to the start of the line
    And I move right
    And I backspace
    Then the contents should be "<c>)0123456789"

  Scenario: Don't type over end if moved away
    When I open a new edit tab
    And I type "0123456789"
    And I move to the start of the line
    And I type "("
    And I move to the end of the line
    And I move to the start of the line
    And I move right
    And I type ")"
    Then the contents should be "())0123456789"

  
  