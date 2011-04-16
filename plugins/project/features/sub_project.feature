@project-fixtures
Feature: Opening subprojects with shared configuration files

  Background:
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory

  Scenario: Opening a subproject
    When I open a "/test1" as a subproject of the current directory
    Then I should see "a.txt,b.txt,c.txt" in the tree
    And "test_config" in the project configuration files

  Scenario: Title of window reflects open subproject
    When I open a "/test1" as a subproject of the current directory
    Then the window should have title "Subproject: test1 in myproject"
