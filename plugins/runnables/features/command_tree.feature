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

  Scenario: I can manually refresh the tree
    When I open the runnables tree
    And I change the command to "A changed app"
    And I open the runnables tree
    And I expand the tree row "fixture_runnables"
    Then I should see "A changed app" in the tree

  # TODO: Refresh on window changes
  # TODO: preserve expanding when refreshing
  # Example of these are available in refresh_directory_tree.feature
