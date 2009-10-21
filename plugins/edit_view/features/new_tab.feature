Feature: Open a new tab

  Scenario: New tab
    When I press "Cmd+N"
    Then there should be one edit tab
    And the tab should be focussed within the notebook
    And the tab should have the keyboard focus

  
  
  
  
