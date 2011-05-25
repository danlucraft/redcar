Feature: Indents Ruby code correctly

  Background:
    Given the indentation rules are like Ruby's
    When I open a new edit tab
    And tabs are hard
    
  Scenario: It should increase indentation after 'def's
    When I insert "def f" at the cursor
    And I move the cursor to 5
    And I insert "\n" at the cursor
    Then the contents should be "def f\n\t"
    
  Scenario: It should decrease indentation on 'end' line
    When I insert "def f\n\t1\n\ten" at the cursor
    And I move the cursor to 12
    And I insert "d" at the cursor
    Then the contents should be "def f\n\t1\nend"
    
  Scenario: It should keep indentation the same if no change
    When I insert "\tfoo" at the cursor
    And I move the cursor to 4
    And I insert "\n" at the cursor
    Then the contents should be "\tfoo\n\t"
    
  Scenario: It should autoindent correctly
    When I insert "\tdef my_awesome_method\n\t\tfoo\n\tend" at the cursor
    And I select from 0 to 33
    And I auto-indent
    Then the contents should be "def my_awesome_method\n\tfoo\nend"
    
  Scenario: It should autoindent correctly
    When I insert "\tdef my_awesome_method\n\t\tfoo\n\tend" at the cursor
    And I select from 0 to 33
    And I auto-indent
    Then the contents should be "def my_awesome_method\n\tfoo\nend"
    When I undo
    Then the contents should be "\tdef my_awesome_method\n\t\tfoo\n\tend"
    
    
        
        