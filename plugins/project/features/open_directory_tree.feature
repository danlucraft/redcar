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
  
  
  
  
