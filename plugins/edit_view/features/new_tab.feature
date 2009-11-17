Feature: Open a new tab

  Scenario: New tab
    When I open a new edit tab
    Then there should be one edit tab
    And the tab should be focussed within the notebook
    And the tab should have the keyboard focus

  Scenario: Close tab
    When I open a new edit tab
    And I close the focussed tab
    Then there should be no open tabs
