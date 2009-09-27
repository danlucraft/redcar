Feature: See a prompt to save when the user closes a tab with changes

  Background:
    Given the file "plugins/edit_tab/features/fixtures/file1.rb" contains "# First Ruby test file"
    And the file "plugins/edit_tab/features/fixtures/file2.rb" contains "# Second Ruby test file"
    And the file "plugins/edit_tab/features/fixtures/new_file.html" does not exist
    And the file "plugins/edit_tab/features/fixtures/new_file.rb" does not exist

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

