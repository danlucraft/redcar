Feature: Multiple windows

  Scenario: Start with one window
    Then there should be one window
  
  Scenario: Open a new window
    When I open a new window
    Then there should be 2 windows
  
  Scenario: Open two new windows
    When I open a new window
    And I open a new window
    Then there should be 3 windows

  Scenario: A new window is focussed
    When I open a new window with title "Second"
    And I open a new edit tab
    Then the window "Second" should have 1 tab
