@svn
Feature: Ignoring external files within a working directory

  Scenario: Ignoring certain files
    When I checkout a local repository
    And I create a wc file named "foo.rb"
    And I ignore "foo.rb"
    Then there should be "0" unindexed files and "0" indexed files

  Scenario: Ignoring all files of a type
    When I checkout a local repository
    And I create a wc file named "foo.rb,bar.rb,README"
    Then there should be "3" unindexed files and "0" indexed files
    When I ignore "rb" files
    Then there should be "1" unindexed files and "0" indexed files