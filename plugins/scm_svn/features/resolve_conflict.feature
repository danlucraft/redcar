@svn
Feature: Resolving conflicts

  Scenario: Resolving a file content conflict
    When I checkout a local repository
    And I create a wc file named "foo.rb"
    And I replace "foo.rb" contents with "Never gonna make you cry"
    And I add "foo.rb" to the index
    And I commit my changes with message "Hark! This is a commit."
    Then if I checkout to a new working copy, it should have "1" files
    And the contents of wc file "foo.rb" in the new copy should be "Never gonna make you cry"
    When I replace "foo.rb" contents with "Never gonna say goodbye"
    And I commit my changes with message "Yarr! This is another commit."
    And I replace "foo.rb" contents in the new copy with "Never gonna tell a lie and hurt you"
    Then if I update my new working copy, it should have "4" files
    And there should be "1" conflicted files in the new copy
    When I replace "foo.rb" contents in the new copy with "Never gonna tell a lie and hurt you"
    And and I resolve "foo.rb" conflicts in the new copy
    Then if I update my new working copy, it should have "1" files
    And there should be "0" conflicted files in the new copy
    And the contents of wc file "foo.rb" in the new copy should be "Never gonna tell a lie and hurt you"
    And I commit my changes in the new copy with message "Commit commit commit again!"
    And if I update my working copy, it should have "1" files
    And the contents of wc file "foo.rb" should be "Never gonna tell a lie and hurt you"
