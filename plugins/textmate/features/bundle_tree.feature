Feature: Show snippets in a tree

  Scenario: Show groups of snippets in the project pane
    When I click Show Bundles in Tree
    Then I should see a tree mirror titled "Bundles"
    And I should see "Ruby" in the tree
    And I should not see "test_bundle" in the tree

  Scenario: Show individual snippets
    When I click Show Bundles in Tree
    And I open "Perl" in the tree
    Then I should see snippets "Loop" listed

  Scenario: Show subgroups of snippets
    When I click Show Bundles in Tree
    And I open "PHP" in the tree
    Then I should see snippet groups "Declarations" listed

# Need to clear cache to make this work
#  Scenario: I can refresh the tree if loaded bundles change
#    When I add a bundle
#    And I click Show Bundles in Tree
#    Then I should see "test_bundle" in the tree