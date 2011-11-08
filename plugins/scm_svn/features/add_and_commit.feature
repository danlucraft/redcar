@svn
Feature: Adding and committing files in a working copy

  Scenario: Adding and committing new files to a repository
    When I checkout a local repository
    And I create a wc file named "README,foo.rb"
    And I add "foo.rb" to the index
    And I commit my changes with message "Hark! This is a commit."
    Then there should be "1" unindexed files and "0" indexed files
    And if I checkout to a new working copy, it should have "1" files

  Scenario: Adding and committing new directories to a repository
    When I checkout a local repository
    And I create a wc directory named "lib"
    And I create a wc file named "lib/foo.rb"
    And I add "lib/foo.rb" to the index
    And I commit my changes with message "Hark! This is a commit."
    Then there should be "0" unindexed files and "0" indexed files
    And if I checkout to a new working copy, it should have "1" files