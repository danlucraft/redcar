Feature: Clear Line

  Background:
    When I open a new edit tab

  Scenario: Macro with typing
    When I start recording a macro
    And I type "hi there "
    And I stop recording a macro
    And I run the last recorded macro
    Then the contents should be "hi there hi there "
  
  Scenario: Check type steps move the cursor correctly
    When I type "hello"
    Then the cursor should be at 5
    
  Scenario: Check navigation steps work
    When I type "hello"
    And I move left
    And I move left
    And I move left
    Then the cursor should be at 2
    
  Scenario: Macro with movement
    When I replace the contents with "foo bar baz"
    And I move the cursor to 0
    And I start recording a macro
    And I move right
    And I move right
    And I move right
    And I move right
    And I stop recording a macro
    And I run the last recorded macro
    Then the cursor should be at 8

  Scenario: Macro with typing and movement
    When I start recording a macro
    And I type "foo"
    And I move left
    And I type "X"
    And I move right
    And I stop recording a macro
    And I run the last recorded macro
    Then the contents should be "foXofoXo"

  Scenario: Macro with typing, movement and commands
    When I replace the contents with "foo\nbar\nbaz\n"
    And I move the cursor to 1
    And I start recording a macro
    And I trim the line
    And I move down
    And I stop recording a macro
    And I run the last recorded macro
    Then the contents should be "f\nb\nbaz\n"
    And the cursor should be at 5

  Scenario: Should be able to run the last macro twice
    When I replace the contents with "foo\nbar\nbaz\nqux\nquux"
    And I move the cursor to 1
    And I start recording a macro
    And I trim the line
    And I move down
    And I stop recording a macro
    And I run the last recorded macro
    And I run the last recorded macro
    Then the contents should be "f\nb\nb\nqux\nquux"
    And the cursor should be at 7
    
  Scenario: Tabs should work correctly in macro
    When tabs are soft, 4 spaces
    And I start recording a macro
    And I type "a\tb"
    And I stop recording a macro
    And I run the last recorded macro
    Then the contents should be "a   ba  b"
  
  Scenario: Delete key in macro
    When I replace the contents with "foo"
    And I move the cursor to 0
    And I start recording a macro
    And I delete
    And I stop recording a macro
    And I run the last recorded macro
    Then the contents should be "o"
    And the cursor should be at 0
  
  
