Feature: Managing a working copy

  Scenario: Checking out a repository via the 'file' protocol
    When I checkout a local repository
    Then I should have a working copy
    
  Scenario: Editing a file and viewing unindexed modified files
    When I checkout a local repository
    And I create a wc file named "README"
    Then there should be "1" unindexed files and "0" indexed files
    
  Scenario: Editing a file and adding to the index
    When I checkout a local repository
    And I create a wc file named "README"
    And I create a wc file named "foo.rb"
    And I add "foo.rb" to the index
    Then there should be "1" unindexed files and "1" indexed files
  
  Scenario: Adding and committing new files to a repository
    When I checkout a local repository
    And I create a wc file named "README"
    And I create a wc file named "foo.rb"
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
  
  Scenario: Updating a working copy
  
  Scenario: Ignoring certain files
  
  Scenario: Ignoring all files of a type
  
  Scenario: Reverting a dirty file to base revision
  
  Scenario: Deleting a file from version control