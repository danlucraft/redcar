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
    When I checkout a local repository
    And I create a wc file named "foo.rb"
    And I add "foo.rb" to the index
    And I commit my changes with message "Hark! This is a commit."
    Then if I checkout to a new working copy, it should have "1" files
    And I create a wc file named "bar.rb"
    When I add "bar.rb" to the index
    And I commit my changes with message "Yarr! This is another commit."
    Then if I update my new working copy, it should have "2" files

  Scenario: Ignoring certain files
    When I checkout a local repository
    And I create a wc file named "foo.rb"
    And I ignore "foo.rb"
    Then there should be "0" unindexed files and "0" indexed files

  Scenario: Ignoring all files of a type
    When I checkout a local repository
    And I create a wc file named "foo.rb"
    And I create a wc file named "bar.rb"
    And I create a wc file named "README"
    Then there should be "3" unindexed files and "0" indexed files
    When I ignore "rb" files
    Then there should be "1" unindexed files and "0" indexed files

  Scenario: Reverting a dirty file to base revision
    When I checkout a local repository
    And I create a wc file named "foo.rb"
    Given I will choose "plugins/scm_svn/features/fixtures/foo.rb" from the "open_file" dialog
    When I open a file
    And I replace the contents with "Never gonna give you up"
    And I save the tab
    And I add "foo.rb" to the index
    And I commit my changes with message "Hark! This is a commit."
    And I replace the contents with "Never gonna let you down"
    And I save the tab
    And I revert "foo.rb"
    Then the file "plugins/scm_svn/features/fixtures/foo.rb" should contain "Never gonna give you up"

  Scenario: Deleting a file from version control
    When I checkout a local repository
    And I create a wc file named "foo.rb"
    And I create a wc file named "bar.rb"
    And I add "foo.rb" to the index
    And I add "bar.rb" to the index
    And I commit my changes with message "Hark! This be a commit."
    And I wc delete "foo.rb"
    And I commit my changes with message "Yarr! Committin' I be!"
    Then if I checkout to a new working copy, it should have "1" files