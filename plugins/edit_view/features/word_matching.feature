Feature: Word Matching

  Scenario: Matching a word at the file start
    When I open a new edit tab
    And I replace the contents with "Don Caballero"
    And I select the word at 0
    Then the selected text should be "Don"
    
  Scenario: Matching a word at the file start by explicitly calling the matching method
    When I open a new edit tab
    And I replace the contents with "Don Caballero"
    And I select the word right of 0
    Then the selected text should be "Don"
    
  Scenario: Matching a word at the file end
    When I open a new edit tab
    And I replace the contents with "Don Caballero"
    And I select the word at 13
    Then the selected text should be "Caballero"
    
  Scenario: Matching a word at the file end by explicitly calling the matching method
    When I open a new edit tab
    And I replace the contents with "Don Caballero"
    And I select the word left of 13
    Then the selected text should be "Caballero"
  
  Scenario: Matching a word from the start of a word
    When I open a new edit tab
    And I replace the contents with "Don Caballero"
    And I select the word at 4
    Then the selected text should be "Caballero"
  
  Scenario: Matching a word from the start of a word by explicitly calling the matching method
    When I open a new edit tab
    And I replace the contents with "Don Caballero"
    And I select the word right of 4
    Then the selected text should be "Caballero"
    
  Scenario: Matching a word from the end of a word
    When I open a new edit tab
    And I replace the contents with "Don Caballero"
    And I select the word at 3
    Then the selected text should be "Don"
    
  Scenario: Matching a word from the end of a word
    When I open a new edit tab
    And I replace the contents with "Don Caballero"
    And I select the word left of 3
    Then the selected text should be "Don"
    
  Scenario: Matching a word from somewhere inside a word
    When I open a new edit tab
    And I replace the contents with "Don Caballero"
    And I select the word at 7
    Then the selected text should be "Caballero"
    
  Scenario: Matching a word from somewhere inside a word by explicitly calling the matching method
    When I open a new edit tab
    And I replace the contents with "Don Caballero"
    And I select the word around 7
    Then the selected text should be "Caballero"
    
  Scenario: Matching a word towards the file start
    When I open a new edit tab
    And I replace the contents with "Don Caballero"
    And I select the word at 1
    Then the selected text should be "Don"