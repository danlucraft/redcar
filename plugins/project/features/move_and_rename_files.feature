Feature: Moving and renaming files

  Background:
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    
  Scenario: Renaming a file which is currently open
    Given I will choose "plugins/project/spec/fixtures/winter.txt" from the "open_file" dialog
    When I open a file
    And I rename "winter.txt" to "summer.txt" in the project tree
    Then my active tab should be "summer.txt"
    And I should see "Wintersmith" in the edit tab
  
  
  