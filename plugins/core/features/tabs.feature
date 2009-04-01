Feature: Open, Save and Close tabs
  As a user
  I want to be able to manage tabs within the Redcar window
  So that I can edit multiple files at the same time

  Background:
    Given the file "plugins/core/features/fixtures/file1.rb" contains "# First Ruby test file"
    And the file "plugins/core/features/fixtures/file2.rb" contains "# Second Ruby test file"

  Scenario: Open more then one file
    When I open the file "plugins/core/features/fixtures/file1.rb"
    And I open the file "plugins/core/features/fixtures/file2.rb"
    Then there should be two EditTabs open

  Scenario: Save all open tabs
    When I open the file "plugins/core/features/fixtures/file1.rb"
    And I type "changed "
    And I open the file "plugins/core/features/fixtures/file2.rb"
    And I type "changed "
    And I save all the open tabs
    Then the file "plugins/core/features/fixtures/file1.rb" should contain "changed # First Ruby test file"
    And the file "plugins/core/features/fixtures/file2.rb" should contain "changed # Second Ruby test file"
