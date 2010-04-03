Feature: Open directory tree

  Scenario: Open directory
    Given I will choose "." from the "open_directory" dialog
    When I open a directory
    Then I should see "bin,config,lib,plugins" in the tree

  Scenario: Open directory then another directory
    Given I will choose "." from the "open_directory" dialog
    When I open a directory
    Given I will choose "plugins" from the "open_directory" dialog
    When I open a directory
    Then I should see "core,application,tree" in the tree
  
  Scenario: Title of window reflects open project
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    Then the window should have title "myproject"

  Scenario: Title of window returns to "Redcar" if directory is closed
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    Then the window should have title "myproject"
    When I close the directory
    Then the window should have title "Redcar"
