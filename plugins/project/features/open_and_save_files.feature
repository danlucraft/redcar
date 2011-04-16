@project-fixtures
Feature: Open and save files

  Scenario: Open a file
    Given I will choose "plugins/project/spec/fixtures/winter.txt" from the "open_file" dialog
    When I open a file
    Then there should be one edit tab
    And I should see "Wintersmith" in the edit tab

  Scenario: Open a file using another Redcar invocation
    Given I open "plugins/project/spec/fixtures/winter.txt" using the redcar command
    Then there should be one edit tab
    And my active tab should be "winter.txt"
    And I should see "Wintersmith" in the edit tab

  Scenario: Open a new file using a Pipe
    Given I pipe "hi" into redcar
    Then there should be one edit tab
    And my active tab should be "untitled"
    And I should see "hi" in the edit tab

  Scenario: Opening an already open file focusses the edit tab
    Given I will choose "plugins/project/spec/fixtures/winter.txt" from the "open_file" dialog
    When I open a file
    And I open a new edit tab
    And I replace the contents with "Jenny Green Eyes"
    And I open a file
    Then there should be 2 edit tabs
    And I should see "Wintersmith" in the edit tab

  Scenario: Save a file
    Given I have opened "plugins/project/spec/fixtures/winter.txt"
    When I replace the contents with "Hi!"
    And I save the tab
    Then the file "plugins/project/spec/fixtures/winter.txt" should contain "Hi!"
    And I should see "Hi!" in the edit tab

  Scenario: Save a file As
    Given I have opened "plugins/project/spec/fixtures/winter.txt"
    And I will choose "plugins/project/spec/fixtures/winter2.txt" from the "save_file" dialog
    And I save the tab as
    Then the file "plugins/project/spec/fixtures/winter2.txt" should contain "Wintersmith"
    And I should see "Wintersmith" in the edit tab

  Scenario: Open a file using another Redcar invocation and waiting for the tab to be closed
    Given I open "plugins/project/spec/fixtures/winter.txt" using the redcar command with "-w"
    And I wait "2" seconds
    Then there should be one edit tab
    And my active tab should be "winter.txt"
    And I should see "Wintersmith" in the edit tab
    And the redcar command should not have returned
    Given I close the focussed tab
    Then the redcar command should have returned

  Scenario: Open a new file using a Pipe and waiting for the tab to be closed
    Given I pipe "hi" into redcar with "-w"
    And I wait "2" seconds
    Then there should be one edit tab
    And my active tab should be "untitled"
    And I should see "hi" in the edit tab
    And the redcar command should not have returned
    Given I will choose "no" from the "message_box" dialog
    And I close the focussed tab
    Then the redcar command should have returned

  Scenario: Open file in nearest ancestor project window
    Given I will choose "plugins/project/spec" from the "open_directory" dialog
    When I open a directory
    Given I will choose "plugins/project/spec/fixtures" from the "open_directory" dialog
    When I open a directory
    Given I will choose "plugins/project/spec/fixtures/winter.txt" from the "open_file" dialog
    When I open a file
    Then the window "fixtures" should have 1 tab

  Scenario: Choosing to open a large file
    Given I will open a large file from the "open_file" dialog
    And I will choose "yes" from the "message_box" dialog
    When I open a file
    Then there should be 1 edit tab

  Scenario: Choosing not to open a large file
    Given I will open a large file from the "open_file" dialog
    And I will choose "no" from the "message_box" dialog
    When I open a file
    Then there should be 0 edit tabs
