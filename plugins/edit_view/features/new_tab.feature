Feature: Open a new tab

  Scenario: New tab
    When I press m"Cmd+N" l"Ctrl+N" w"Ctrl+N"
    Then there should be one edit tab
    And the tab should be focussed within the notebook
    And the tab should have the keyboard focus

  Scenario: Close tab
    When I press "Cmd+N"
    And I press "Cmd+W"
    Then there should be no open tabs
