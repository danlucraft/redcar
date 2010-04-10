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
    Then I should see "Newton" in the edit tab
    When I open a new edit tab
    Then I should not see a "message_box" dialog for the rest of the feature
    And I close the focussed tab
  