Feature: Create, Open and Save files
  As a user
  I want to be able to load and save files

  Background:
    Given the file "plugins/edit_tab/features/fixtures/file1.rb" contains "# First Ruby test file"
    And the file "plugins/edit_tab/features/fixtures/file2.rb" contains "# Second Ruby test file"
    And the file "plugins/edit_tab/features/fixtures/new_file.html" does not exist
    And the file "plugins/edit_tab/features/fixtures/new_file.rb" does not exist

  Scenario: Open a file
    When I press "Ctrl+O"
    And I set the "Open" dialog's filename to "plugins/edit_tab/features/fixtures/file1.rb"
    And I click the button "Open" in the dialog "Open"
    Then there should be one EditTab open
    And I should see "# First Ruby test file" in the EditTab
    And the label of the EditTab should say "file1.rb"

  Scenario: Opening a file more than once should not open more than one tab
    When I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    And I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    Then there should be one EditTab open

  Scenario: Change a file changes the label
    When I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    And I type "a"
    And the label of the EditTab should say "file1.rb*"

  Scenario: Change a file and save it changes the label
    Given I have opened the file "plugins/edit_tab/features/fixtures/file1.rb"
    When I type "a"
    And I save the EditTab
    Then the label of the EditTab should say "file1.rb"

  Scenario: Undoing all the way removes * from the label
    Given I have opened the file "plugins/edit_tab/features/fixtures/file1.rb"
    When I type "a"
    And I press "Ctrl+Z"
    Then the label of the EditTab should say "file1.rb"

  Scenario: Change a file and save it changes the file on disk
    Given I have opened the file "plugins/edit_tab/features/fixtures/file1.rb"
    When I type "changed "
    And I save the EditTab
    And I close the tab
    And I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    Then I should see "changed # First" in the EditTab

  Scenario: Save As
    Given I have opened the file "plugins/edit_tab/features/fixtures/file1.rb"
    When I press "Ctrl+Shift+S"
    And I set the "Save As" dialog's filename to "plugins/edit_tab/features/fixtures/new_file.rb"
    And I click the button "Save" in the dialog "Save As"
    And I close the tab
    And I open the file "plugins/edit_tab/features/fixtures/new_file.rb"
    Then I should see "# First" in the EditTab

  Scenario: Change a file then save as changes the label
    Given I have opened the file "plugins/edit_tab/features/fixtures/file1.rb"
    When I type "a"
    And I save the EditTab as "plugins/edit_tab/features/fixtures/new_file.rb"
    Then the label of the EditTab should say "new_file.rb"

  Scenario: Changing the file extension changes the grammar
    Given I have opened the file "plugins/edit_tab/features/fixtures/file1.rb"
    When I save the EditTab as "plugins/edit_tab/features/fixtures/new_file.html"
    Then the current syntax should be "HTML"

  Scenario: Open more then one file
    When I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    And I open the file "plugins/edit_tab/features/fixtures/file2.rb"
    Then there should be two EditTabs open

  Scenario: Save all open tabs
    When I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    And I type "changed "
    And I open the file "plugins/edit_tab/features/fixtures/file2.rb"
    And I type "changed "
    And I save all the open tabs
    Then the file "plugins/edit_tab/features/fixtures/file1.rb" should contain "changed # First Ruby test file"
    And the file "plugins/edit_tab/features/fixtures/file2.rb" should contain "changed # Second Ruby test file"

  Scenario: Undo close tab
    When I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    And I press "Ctrl+W"
    And I press "Ctrl+Shift+T"
    Then the label of the EditTab should say "file1.rb"

  Scenario: Undo two close tabs
    When I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    And I open the file "plugins/edit_tab/features/fixtures/file2.rb"
    And I press "Ctrl+W"
    And I press "Ctrl+W"
    And I press "Ctrl+Shift+T"
    And I press "Ctrl+Shift+T"
    Then there should be two EditTabs open

  Scenario: Save a file you do not have permission to modify
    Given I do not have permission to write to "/etc/X11/xorg.conf"
    When I open the file "/etc/X11/xorg.conf"
    And I type "Haha changes can't get saved"
    And I press "Ctrl+S"
    Then I should see "don't have permission" in a dialog
