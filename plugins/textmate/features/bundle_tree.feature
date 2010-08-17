Feature: Show snippets in a tree

  Scenario: Show groups of snippets in the project pane
    When I click Show Bundles in Tree
    Then I should see a tree mirror titled "Bundles"
    And I should see bundle names, like "a bundle" in the tree

  Scenario: Show individual snippets
    When I open "a bundle" in the tree
    Then I should see snippets "a snippet,b snippet,c snippet" listed

  Scenario: Show subgroups of snippets
    When I open "big bundle" in the tree
    Then I should see snippet groups "a group,b group,c group" listed

  Scenario: I can refresh the tree if loaded bundles change
    When I add a bundle
    And I click Show Bundles in Tree
    Then I should see "test_bundle" in the tree