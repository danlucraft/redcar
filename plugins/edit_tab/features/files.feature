Feature: Create, Open and Save files
  As a user
  I want to be able to load and save files

  Background:
    Given the file "plugins/edit_tab/features/fixtures/files.rb" contains "test files file"
    And the file "plugins/edit_tab/features/fixtures/files2.html" does not exist

  Scenario: Open a file
    When I open the file "plugins/edit_tab/features/fixtures/files.rb"
    Then there should be one EditTab open
    And I should see "test files file" in the EditTab
    And the label of the EditTab should say "files.rb"

  Scenario: Change a file changes the label
    When I open the file "plugins/edit_tab/features/fixtures/files.rb"
    And I type "a"
    And the label of the EditTab should say "files.rb*"

  Scenario: Change a file and save it changes the label
    Given I have opened the file "plugins/edit_tab/features/fixtures/files.rb"
    When I type "a"
    And I save the EditTab
    Then the label of the EditTab should say "files.rb"

  Scenario: Change a file and save it changes the file on disk
    Given I have opened the file "plugins/edit_tab/features/fixtures/files.rb"
    When I type "changed "
    And I save the EditTab
    And I close the tab
    And I open the file "plugins/edit_tab/features/fixtures/files.rb"
    Then I should see "changed test files file" in the EditTab

  Scenario: Save As
    Given I have opened the file "plugins/edit_tab/features/fixtures/files.rb"
    When I save the EditTab as "plugins/edit_tab/features/fixtures/files2.rb"
    And I close the tab
    And I open the file "plugins/edit_tab/features/fixtures/files2.rb"
    Then I should see "test files file" in the EditTab

  Scenario: Change a file then save as changes the label
    Given I have opened the file "plugins/edit_tab/features/fixtures/files.rb"
    When I type "a"
    And I save the EditTab as "plugins/edit_tab/features/fixtures/files2.rb"
    Then the label of the EditTab should say "files2.rb"

  Scenario: Changing the file extension changes the grammar
    Given I have opened the file "plugins/edit_tab/features/fixtures/files.rb"
    When I save the EditTab as "plugins/edit_tab/features/fixtures/files2.html"
    Then the current syntax should be "HTML"
