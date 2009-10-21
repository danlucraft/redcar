Feature: Open a new tab

  Scenario: New tab
    Then the window should have title "Redcar"
    When I press "Cmd+N"
    Then there should be one edit tab

  
  
  
  
