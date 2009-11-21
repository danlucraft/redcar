Feature: Open and save files

  Scenario: Open a file
    Given I will choose "plugins/project/features/fixtures/winter.txt" from the "open_file" dialog
    When I open a file
    Then there should be one edit tab
    And I should see "Wintersmith" in the edit tab
  
  Scenario: Save a file
    Given I have opened "plugins/project/features/fixtures/winter.txt"
    When I replace the contents with "Hi!"
    And I save the tab
    Then the file "plugins/project/features/fixtures/winter.txt" should contain "Hi!"
    And I should see "Hi!" in the edit tab

  Scenario: Save a file As
    Given I have opened "plugins/project/features/fixtures/winter.txt"
    And I will choose "plugins/project/features/fixtures/winter2.txt" from the "save_file" dialog
    And I save the tab as
    Then the file "plugins/project/features/fixtures/winter2.txt" should contain "Wintersmith"
    And I should see "Wintersmith" in the edit tab

