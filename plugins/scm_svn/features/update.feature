@svn
Feature: Updating a working copy from a remote repository

  Scenario: Updating a working copy
    When I checkout a local repository
    And I create a wc file named "foo.rb"
    And I replace "foo.rb" contents with "Never gonna make you cry"
    And I add "foo.rb" to the index
    And I commit my changes with message "Hark! This is a commit."
    Then if I checkout to a new working copy, it should have "1" files
    And the contents of wc file "foo.rb" in the new copy should be "Never gonna make you cry"
    When I replace "foo.rb" contents with "Never gonna say goodbye"
    And I create a wc file named "bar.rb"
    And I add "bar.rb" to the index
    And I commit my changes with message "Yarr! This is another commit."
    Then if I update my new working copy, it should have "2" files
    And the contents of wc file "foo.rb" in the new copy should be "Never gonna say goodbye"