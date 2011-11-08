@svn
Feature: Checking out a repository

  Scenario: Checking out a repository via the 'file' protocol
    When I checkout a local repository
    Then I should have a working copy