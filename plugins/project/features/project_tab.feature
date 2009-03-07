Feature: The Project Tab
  As a User
  I want to navigate through my projects easily

  Scenario: Should set open the tab and set the title
    When I press "Ctrl+Shift+P"
    Then there should be one ProjectTab open
    And the title of the ProjectTab should be "Project"

