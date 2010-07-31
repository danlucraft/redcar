Feature: Main menu

  Scenario: There should be File and Help menus
    Then the main menu should contain "File, Help" entries
  
  Scenario: There should be a File|New entry
    Then the "File" menu should contain a "New" entry