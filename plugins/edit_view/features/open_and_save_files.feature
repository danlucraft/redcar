Feature: Open and save files

  Scenario: Open a file
    Given I will choose "plugins/edit_view/features/fixtures/winter.txt" from the open_file dialog
    When I press "Cmd+O"
    Then there should be one edit tab
    And I should see "Wintersmith" in the edit tab
  
