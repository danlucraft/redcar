@svn
Feature: Opening other branches as new projects

  Scenario: Opening a branch from trunk
    When I checkout a local repository
    And I create a wc directory named "trunk,branches,branches/version1,branches/version2"
    And I create a wc file named "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt"
    And I add "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt" to the index
    And I commit my changes with message "Initial commit"
    Given I will open "trunk" branch as a new project
    When I open a directory
    And I note the number of windows
    And I switch to "version1" branch
    Then I should see 1 more window
    And the window should have title "version1"

  Scenario: Opening a branch from another branch
    When I checkout a local repository
    And I create a wc directory named "trunk,branches,branches/version1,branches/version2"
    And I create a wc file named "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt"
    And I add "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt" to the index
    And I commit my changes with message "Initial commit"
    Given I will open "version1" branch as a new project
    When I open a directory
    And I note the number of windows
    And I switch to "version2" branch
    Then I should see 1 more window
    And the window should have title "version2"

  Scenario: Opening trunk from a branch
    When I checkout a local repository
    And I create a wc directory named "trunk,branches,branches/version1,branches/version2"
    And I create a wc file named "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt"
    And I add "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt" to the index
    And I commit my changes with message "Initial commit"
    Given I will open "version1" branch as a new project
    When I open a directory
    And I note the number of windows
    And I switch to "trunk" branch
    Then I should see 1 more window
    And the window should have title "trunk"

  Scenario: Attempting to open the same branch from the branching dialog
    When I checkout a local repository
    And I create a wc directory named "trunk,branches,branches/version1,branches/version2"
    And I create a wc file named "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt"
    And I add "trunk/a.txt,branches/version1/b.txt,branches/version2/c.txt" to the index
    And I commit my changes with message "Initial commit"
    Given I will open "version1" branch as a new project
    When I open a directory
    And I note the number of windows
    And I switch to "version1" branch
    Then I should see 0 more windows
    And the window should have title "version1"
