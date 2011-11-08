@svn
Feature: Editing and indexing files in a working copy

  Scenario: Editing a file and viewing unindexed modified files
    When I checkout a local repository
    And I create a wc file named "README"
    Then there should be "1" unindexed files and "0" indexed files

  Scenario: Editing a file and adding to the index
    When I checkout a local repository
    And I create a wc file named "README,foo.rb"
    And I add "foo.rb" to the index
    Then there should be "1" unindexed files and "1" indexed files