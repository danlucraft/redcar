Feature: Indents Ruby code correctly

  Background:
    Given the indentation rules are like Ruby's
    When I open a new edit tab
    And tabs are hard
    
  Scenario: It should increase indentation after 'def's
    Given I replace the contents with "def f"
    And I move the cursor to (0,5)
    And I type "\n"
    Then the contents should be "def f\n\t"
    
  Scenario: It should decrease indentation on 'end' line
    When I replace the contents with "def f\n\t1\n\ten"
    And I move the cursor to (2,3)
    And I type "d"
    Then the contents should be "def f\n\t1\nend"
    
  Scenario: It should keep indentation the same if no change
    When I replace the contents with "\tfoo"
    And I move the cursor to (0,4)
    And I type "\n"
    Then the contents should be "\tfoo\n\t"
    
  Scenario: It should autoindent correctly
    When I replace the contents with "\tdef my_awesome_method\n\t\tfoo\n\tend"
    And I select from (0,0) to (2,4)
    And I auto-indent
    Then the contents should be "def my_awesome_method\n\tfoo\nend"
    
  Scenario: It should autoindent correctly
    When I replace the contents with "\tdef my_awesome_method\n\t\tfoo\n\tend"
    And I select from (0,0) to (2,4)
    And I auto-indent
    Then the contents should be "def my_awesome_method\n\tfoo\nend"
    When I undo
    Then the contents should be "\tdef my_awesome_method\n\t\tfoo\n\tend"
    
    
        
        