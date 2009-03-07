Feature: The Project Tab
  As a User
  I want to navigate through my projects easily

  Scenario: Open the project tab
    When I press "Ctrl+Shift+P"
    And I press "2"
    Then there should be one ProjectTab open
    And the title of the ProjectTab should be "Project"

  Scenario: Shows the menu
    Given I have opened the ProjectTab
    When I right click on the ProjectTab
    Then I should see a menu with "Add Project Directory"

  Scenario: Add a directory, adds directory, subdirectories and files
    Given I have opened the ProjectTab
    When I add the directory "plugins/project" to the ProjectTab
    Then I should see "project" in the ProjectTab
    And I should see "commands" in the ProjectTab   
    And I should see "plugin.rb" in the ProjectTab
