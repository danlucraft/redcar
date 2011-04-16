@project-fixtures
Feature: Close directory tree

  Scenario: Close and re-open directory stays in the same window
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    Then there should be 1 windows
    When I close the directory
    When I open a directory
    Then there should be 1 windows

  Scenario: Close directory via close icon
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    And I click the close button
    Then the tree width should be the minimum size
    And the window should have title "Redcar"
    When I open a directory
    Then there should be 1 windows

  Scenario: Close directory via "Close Tree" menu item
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    And I close the tree
    Then the tree width should be the minimum size
    And the window should have title "Redcar"
    When I open a directory
    Then there should be 1 windows
