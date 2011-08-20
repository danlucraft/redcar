Feature: Main menu

  Scenario: There should be File and Help menus
    Then there should be a main menu
    And the main menu should contain "File, Help" entries
  
  Scenario: There should be a File|New entry
    Then there should be a main menu
    And the "File" menu should contain a "New" entry
