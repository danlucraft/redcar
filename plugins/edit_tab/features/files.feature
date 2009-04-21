Feature: Create, Open and Save files
  As a user
  I want to be able to load and save files

  Background:
    Given the file "plugins/edit_tab/features/fixtures/files.rb" contains "test files file"
    And the file "plugins/core/features/fixtures/file1.rb" contains "# First Ruby test file"
    And the file "plugins/core/features/fixtures/file2.rb" contains "# Second Ruby test file"
    And the file "plugins/edit_tab/features/fixtures/files2.html" does not exist

  Scenario: Open a file
    When I open the file "plugins/edit_tab/features/fixtures/files.rb"
    Then there should be one EditTab open
    And I should see "test files file" in the EditTab
    And the label of the EditTab should say "files.rb"

  Scenario: Opening a file more than once should not open more than one tab
    When I open the file "plugins/edit_tab/features/fixtures/files.rb"
    And I open the file "plugins/edit_tab/features/fixtures/files.rb"
    Then there should be one EditTab open

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

  Scenario: Undo close tab
    When I open the file "plugins/core/features/fixtures/file1.rb"
    And I press "Ctrl+W"
    And I press "Ctrl+Shift+T"
    Then the label of the EditTab should say "file1.rb"

  Scenario: Undo two close tabs
    When I open the file "plugins/core/features/fixtures/file1.rb"
    And I open the file "plugins/core/features/fixtures/file2.rb"
    And I press "Ctrl+W"
    And I press "Ctrl+W"
    And I press "Ctrl+Shift+T"
    And I press "Ctrl+Shift+T"
    Then there should be two EditTabs open

  Scenario: Prompt for save for modified file
    When I open the file "plugins/core/features/fixtures/file1.rb"
    And I type "changed"
    And I press "Ctrl+W"
    Then I should see a dialog "Document has unsaved changes" with buttons "Save, Discard, Cancel"

  Scenario: Prompt for save should save
    When I open the file "plugins/core/features/fixtures/file1.rb"
    And I type "changed"
    And I press "Ctrl+W"
    And I click the button "Save" in the dialog like "unsaved changes"





