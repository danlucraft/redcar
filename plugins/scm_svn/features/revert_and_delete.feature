@svn
Feature: Reverting and deleting files in a working copy

  Scenario: Reverting a dirty file to base revision
    When I checkout a local repository
    And I create a wc file named "foo.rb"
    And I replace "foo.rb" contents with "Never gonna give you up"
    And I add "foo.rb" to the index
    And I commit my changes with message "Hark! This is a commit."
    And I replace "foo.rb" contents with "Never gonna let you down"
    And I revert "foo.rb"
    Then there should be "0" unindexed files and "0" indexed files
    And the contents of wc file "foo.rb" should be "Never gonna give you up"

  Scenario: Deleting a file from version control
    When I checkout a local repository
    And I create a wc file named "foo.rb,bar.rb"
    And I add "foo.rb,bar.rb" to the index
    And I commit my changes with message "Hark! This be a commit."
    And I wc delete "foo.rb"
    And I commit my changes with message "Yarr! Committin' I be!"
    Then if I checkout to a new working copy, it should have "1" files