Feature: Updating a working copy from a remote repository

  Scenario: Updating a working copy
    When I checkout a local repository
    And I create a wc file named "foo.rb"
    And I add "foo.rb" to the index
    And I commit my changes with message "Hark! This is a commit."
    Then if I checkout to a new working copy, it should have "1" files
    And I create a wc file named "bar.rb"
    When I add "bar.rb" to the index
    And I commit my changes with message "Yarr! This is another commit."
    Then if I update my new working copy, it should have "2" files