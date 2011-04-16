@project-fixtures
Feature: Open directory tree

  Scenario: Open directory
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    Then the window should have title "myproject"
    Then I should see "lib,spec,vendor,README" in the tree

  Scenario: Open a directory using another Redcar invocation
    Given I open "plugins/project/spec/fixtures/myproject" using the redcar command
    Then the window should have title "myproject"

  Scenario: Open directory then another directory
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    Given I will choose "plugins/project/spec/fixtures/myproject/lib" from the "open_directory" dialog
    When I open a directory
    Then I should see "foo_lib.rb" in the tree

  Scenario: Open a directory and then the same using another Redcar invocation
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    And I open "plugins/project/spec/fixtures/myproject" using the redcar command
    Then there should be 1 windows
    And the window should have title "myproject"

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

  Scenario: Directory keeps the same width if maximized
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    Then the tree width should be the default
    When I maximize the window size
    Then the tree width should be the default
    When I restore the window size
    Then the tree width should be the default

  Scenario: Toggle Tree Visibility hides the treebook if the tab title is visible, else it opens it
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    And I set the treebook width to the default
    And I toggle tree visibility
    Then the tree width should be the minimum size
    When I set the treebook width to only a few pixels
    And I toggle tree visibility
    Then the tree width should be the default

  Scenario: Treebook becomes visible if hidden and another tree is opened
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    And I set the treebook width to the default
    And I toggle tree visibility
    Then the tree width should be the minimum size
    When I open the runnables tree
    Then the tree width should be the default
    And I toggle tree visibility
    Then the tree width should be the minimum size
    
  Scenario: Treebooks should keep open to their previous open width
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    When I set the treebook width to the default
    And I set the treebook width to 50 pixels
    And I toggle tree visibility
    Then the tree width should be the minimum size
    When I toggle tree visibility
    Then the tree width should be 50 pixels
    When I set the treebook width to 250 pixels
    And I toggle tree visibility
    And I toggle tree visibility
    Then the tree width should be 250 pixels
    When I toggle tree visibility
    And I set the treebook width to 35 pixels
    And I toggle tree visibility
    Then the tree width should be the minimum size

# RSpec matchers have trouble with the multibyte string
#  Scenario: Multibyte files and directories
#    Given I will choose "plugins/project/spec/fixtures/multi-byte-files" from the "open_directory" dialog
#    When I open a directory
#    Then the window should have title "multi-byte-files"
#    Then I should see "a경로,테스트.py" in the tree
