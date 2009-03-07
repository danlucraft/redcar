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

  Scenario: Add a project directory, adds directory, subdirectories and files
    Given I have opened the ProjectTab
    When I add the directory "plugins/project" to the ProjectTab
    Then I should see "project" in the ProjectTab
    And I should see "commands" in the ProjectTab   
    And I should see "plugin.rb" in the ProjectTab
    And I should not see "step_definitions" in the ProjectTab
    And I should not see "[dummy row]" in the ProjectTab

  Scenario: Remove a project directory
    Given I have opened the ProjectTab
    When I add the directory "plugins/project" to the ProjectTab
    And I remove the directory "plugins/project" from the ProjectTab
    Then I should not see "project" in the ProjectTab

  Scenario: Remove a project directory by giving a subdirectory
    Given I have opened the ProjectTab
    When I add the directory "plugins/project" to the ProjectTab
    And I remove the directory "plugins/project/spec" from the ProjectTab
    Then I should not see "project" in the ProjectTab

  Scenario: Open a subdirectory
    Given I have opened the ProjectTab
    And I have added the directory "plugins/project" to the ProjectTab
    When I open "features" in the ProjectTab
    Then I should see "step_definitions" in the ProjectTab
    And I should see "env.rb" in the ProjectTab
    And I should not see "[dummy row]" in the ProjectTab

  Scenario: Close a subdirectory
    Given I have opened the ProjectTab
    And I have added the directory "plugins/project" to the ProjectTab
    When I close "features" in the ProjectTab
    Then I should not see "step_definitions" in the ProjectTab

  Scenario: Should reload subdirectories
    Given I have opened the ProjectTab
    And I have added the directory "plugins/project" to the ProjectTab
    When I open "features" in the ProjectTab
    And I should not see "astoria.txt" in the ProjectTab
    And I close "features" in the ProjectTab
    And I create a file "astoria.txt" in the project plugin's features directory
    And I open "features" in the ProjectTab
    Then I should see "astoria.txt" in the ProjectTab
    And I cleanup the file "astoria.txt" in the project plugin's features directory





