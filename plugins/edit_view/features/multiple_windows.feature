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

  Scenario: Close a window
    When I open a new window
    And I close the window via command
    Then there should be one window

  Scenario: Close a window
    When I open a new window
    And I close the window via the gui
    Then there should be one window

  Scenario: A new window is focussed
    When I open a new window with title "Second"
    And I open a new edit tab
    Then the window "Second" should have 1 tab
  
  Scenario: The focus returns the first window when I close the second
    When I open a new window
    And I close the window via command
    And I open a new edit tab
    Then the window "Redcar 0" should have 1 tab

  Scenario: The focus returns the first window when I close the second
    When I open a new window
    And I close the window via the gui
    And I open a new edit tab
    Then the window "Redcar 0" should have 1 tab
