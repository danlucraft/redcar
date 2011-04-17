@runnables
Feature: Showing commands in a command tree

  Background:
    When I will choose "plugins/runnables/features/fixtures" from the "open_directory" dialog
    And I open a directory

  Scenario: Shows grouped commands from .redcar/runnables/*.json in the project
    When I open the runnables tree
    Then I should see "fixture_runnables" in the tree

  Scenario: Shows individual commands in groups
    When I open the runnables tree
    And I expand the tree row "fixture_runnables"
    Then I should see "An app" in the tree

  Scenario: Shows groups and subgroups by slash-separated type
    When I open the runnables tree
    And I expand the tree row "fixture_runnables"
    Then I should see "first" in the tree
    And I expand the tree row "first"
    Then I should see "second" in the tree
    And I expand the tree row "second"
    Then I should see "A nested app" in the tree

  Scenario: I can manually refresh the tree
    When I open the runnables tree
    And I change the command to "A changed app"
    And I open the runnables tree
    And I expand the tree row "fixture_runnables"
    Then I should see "A changed app" in the tree

  Scenario: I can switch forth and back between project and runnables tree
    When I open the runnables tree
    And I click the project tree tab
    Then I should not see "fixture_runnables" in the tree
    When I left-click the "Runnables" tree tab
    Then I should see "fixture_runnables" in the tree

  Scenario: Right-clicking the runnables tab does not activate it
    When I open the runnables tree
    And I click the project tree tab
    Then I should not see "fixture_runnables" in the tree
    When I right-click the "Runnables" tree tab
    Then I should not see "fixture_runnables" in the tree
    
  Scenario: Closing the project via icon closes the runnables tree
    And I open the runnables tree
    And I click the project tree tab
    And I click the close button
    Then the tree width should be the minimum size
    And there should not be a tree titled "Runnables"
    
  Scenario: Closing the project via menu item closes the runnables tree
    And I open the runnables tree
    And I click the project tree tab
    And I close the tree
    Then the tree width should be the minimum size
    And there should not be a tree titled "Runnables"

  # TODO: Refresh on window changes
  # TODO: preserve expanding when refreshing
  # Example of these are available in refresh_directory_tree.feature
