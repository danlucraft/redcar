@project-fixtures
Feature: Watch for modified files
  If an open file has changed on disc since the last time the user looked at it,
  then reload the contents. Alert the user if they have made modifications.

  Background:
    Given I will choose "plugins/project/spec/fixtures/winter.txt" from the "open_file" dialog
    When I open a file

  Scenario: Without modifications
    Then there should be one edit tab
    And I should see "Wintersmith" in the edit tab
    When I open a new edit tab
    And I wait "2" seconds
    And I put "Summer" into the file "plugins/project/spec/fixtures/winter.txt"
    And I close the focussed tab
    And the edit tab updates its contents
    Then I should see "Summer" in the edit tab

  Scenario: With modifications, reloading from disc
    Then there should be one edit tab
    And I should see "Wintersmith" in the edit tab
    And I replace the contents with "FOFOOF"
    When I open a new edit tab
    And I wait "2" seconds
    And I put "Summer" into the file "plugins/project/spec/fixtures/winter.txt"
    Given I will choose "yes" from the "message_box" dialog
    And I close the focussed tab
    And the edit tab updates its contents
    Then I should see "Summer" in the edit tab

  Scenario: With modifications, keeping modified version
    Then there should be one edit tab
    And I should see "Wintersmith" in the edit tab
    And I replace the contents with "Newton"
    When I open a new edit tab
    And I wait "2" seconds
    And I put "Summer" into the file "plugins/project/spec/fixtures/winter.txt"
    Given I will choose "no" from the "message_box" dialog
    And I close the focussed tab
    And the edit tab updates its contents
    Then I should see "Newton" in the edit tab

  Scenario: With modifications, keeping modified version, twice
    Then there should be one edit tab
    And I should see "Wintersmith" in the edit tab
    And I replace the contents with "Newton"
    When I open a new edit tab
    And I wait "2" seconds
    And I put "Summer" into the file "plugins/project/spec/fixtures/winter.txt"
    Given I will choose "no" from the "message_box" dialog
    And I close the focussed tab
    And the edit tab updates its contents
    Then I should see "Newton" in the edit tab
    When I open a new edit tab
    Then I should not see a "message_box" dialog for the rest of the feature
    And I close the focussed tab

  Scenario: Keep in the same position in the file when reloading
    Given I close the focussed tab
    And I put a lot of lines into the file "plugins/project/spec/fixtures/winter.txt"
    When I open a file
    And I move to line 100
    Then there should be one edit tab
    When I open a new edit tab
    And I wait "2" seconds
    And I put a lot of lines into the file "plugins/project/spec/fixtures/winter.txt"
    And I close the focussed tab
    Then the cursor should be on line 100

  Scenario: Move to the top if the line you were on is no longer there
    Given I close the focussed tab
    And I put a lot of lines into the file "plugins/project/spec/fixtures/winter.txt"
    When I open a file
    And I move to line 100
    Then there should be one edit tab
    When I open a new edit tab
    And I wait "2" seconds
    And I put "Summer" into the file "plugins/project/spec/fixtures/winter.txt"
    And I close the focussed tab
    And the edit tab updates its contents
    Then the cursor should be on line 0

  Scenario: The file being mirrored by the current unmodified tab is externally deleted
    Then there should be one edit tab
    And I should see "Wintersmith" in the edit tab
    When I open a new window with title "new"
    When I wait "2" seconds
    And "plugins/project/spec/fixtures/winter.txt" goes missing
    And I close the window "new" through the gui
    And I focus the window "Redcar" through the gui
    Then there should be one edit tab
    And the edit tab updates its contents
    And my active tab should have an "exclamation" icon

  Scenario: The file being mirrored by the current modified tab is externally deleted
    Then there should be one edit tab
    And I should see "Wintersmith" in the edit tab
    When I replace the contents with "Jenny Green Eyes"
    And I open a new window with title "new"
    And I wait "2" seconds
    And "plugins/project/spec/fixtures/winter.txt" goes missing
    And I close the window "new" through the gui
    And I focus the window "Redcar" through the gui
    Then my active tab should have an "exclamation" icon
    When I save the tab
    Then my active tab should have an "file" icon


