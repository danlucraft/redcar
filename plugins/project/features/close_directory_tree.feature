@project-fixtures
Feature: Close directory tree

  Scenario: Close directory via close icon
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    And I click the close button
    Then the tree width should be the minimum size
    And the window should have title "Redcar"

  Scenario: Close directory via "Close Tree" menu item
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    And I close the tree
    Then the tree width should be the minimum size
    And the window should have title "Redcar"
