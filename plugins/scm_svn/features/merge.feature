@svn
Feature: Merging two branches together

  Scenario: Merging a branch into trunk
    When I checkout a local repository
    And I create a wc directory named "trunk,branches,branches/version1,branches/version2"
    And I create a wc file named "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt"
    And I add "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt" to the index
    And I commit my changes with message "Initial commit"
    Given I will open "trunk" branch as a new project
    When I open a directory
    And I merge the "version1" branch
    Then I should see "b.txt" in "trunk" branch

  Scenario: Merging two branches together
    When I checkout a local repository
    And I create a wc directory named "trunk,branches,branches/version1,branches/version2"
    And I create a wc file named "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt"
    And I add "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt" to the index
    And I commit my changes with message "Initial commit"
    Given I will open "version1" branch as a new project
    When I open a directory
    And I merge the "version2" branch
    Then I should see "c.txt" in "version1" branch

  Scenario: Merging trunk into a branch
    When I checkout a local repository
    And I create a wc directory named "trunk,branches,branches/version1,branches/version2"
    And I create a wc file named "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt"
    And I add "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt" to the index
    And I commit my changes with message "Initial commit"
    Given I will open "version2" branch as a new project
    When I open a directory
    And I merge the "trunk" branch
    Then I should see "a.txt" in "version2" branch