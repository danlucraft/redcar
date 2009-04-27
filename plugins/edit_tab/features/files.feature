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

  Scenario: Change a file and save it changes the file on disk
    Given I have opened the file "plugins/edit_tab/features/fixtures/file1.rb"
    When I type "changed "
    And I save the EditTab
    And I close the tab
    And I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    Then I should see "changed # First" in the EditTab

  Scenario: Save As
    Given I have opened the file "plugins/edit_tab/features/fixtures/file1.rb"
    When I save the EditTab as "plugins/edit_tab/features/fixtures/new_file.rb"
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

  Scenario: Prompt for save for modified file
    When I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    And I type "changed"
    And I press "Ctrl+W"
    Then I should see a dialog "Document has unsaved changes" with buttons "Save, Discard, Cancel"

  Scenario: Prompt for save and click save
    When I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    And I type "changed "
    And I press "Ctrl+W"
    And I click the button "Save" in the dialog "unsaved changes"
    Then the file "plugins/edit_tab/features/fixtures/file1.rb" should contain "changed # First Ruby test file"
    And there should be zero EditTabs open

  Scenario: Prompt for save and click discard
    When I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    And I type "changed "
    And I press "Ctrl+W"
    And I click the button "Discard" in the dialog "unsaved changes"
    Then the file "plugins/edit_tab/features/fixtures/file1.rb" should contain "# First Ruby test file"
    And there should be zero EditTabs open

  Scenario: Prompt for save and click cancel
    When I open the file "plugins/edit_tab/features/fixtures/file1.rb"
    And I type "changed "
    And I press "Ctrl+W"
    And I click the button "Cancel" in the dialog "unsaved changes"
    Then the file "plugins/edit_tab/features/fixtures/file1.rb" should contain "# First Ruby test file"
    And there should be one EditTabs open

  Scenario: Prompt for save for new tab
    When I press "Ctrl+T"
    And I type "new tab"
    And I press "Ctrl+W"
    Then I should see a dialog "Document has unsaved changes" with buttons "Save As, Discard, Cancel"

  Scenario: Prompt for save new tab and click Save As shows dialog
    When I press "Ctrl+T"
    And I type "new tab"
    And I press "Ctrl+W"
    And I click the button "Save As" in the dialog "unsaved changes"
    Then I should see a dialog "Save As" with buttons "Save, Cancel"

  Scenario: Prompt for save new tab and Save As
    When I press "Ctrl+T"
    And I type "new tab"
    And I press "Ctrl+W"
    And I click the button "Save As" in the dialog "unsaved changes"
    And I set the "Save As" dialog's filename to "plugins/edit_tab/features/fixtures/new_file.rb"
    And I click the button "Save" in the dialog "Save As"
    Then there should be no dialog called "Save As"
    And the file "plugins/edit_tab/features/fixtures/new_file.rb" should contain "new tab"

  Scenario: Prompt for save, choose Save As, then Cancel
    When I press "Ctrl+T"
    And I type "new tab"
    And I press "Ctrl+W"
    And I click the button "Save As" in the dialog "unsaved changes"
    And I set the "Save As" dialog's filename to "plugins/edit_tab/features/fixtures/new_file.rb"
    And I click the button "Cancel" in the dialog "Save As"
    Then there should be no dialog called "Save As"
    And the file "plugins/edit_tab/features/fixtures/new_file.rb" should not exist
    And there should be one EditTab open







