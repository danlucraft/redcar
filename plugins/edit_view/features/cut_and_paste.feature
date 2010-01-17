Feature: Cut and Paste

  Scenario: Cut removes the text
    When I open a new edit tab
    And I replace the contents with "Frank"
    And I select from 0 to 3
    And I cut text
    Then I should not see "Fra" in the edit tab  
    And I should see "nk" in the edit tab  

  Scenario: Copy leaves the text
    When I open a new edit tab
    And I replace the contents with "Frank"
    And I select from 0 to 3
    And I copy text
    Then I should see "Frank" in the edit tab  

  Scenario: Paste inserts the cut text
    When I open a new edit tab
    And I replace the contents with "Frank"
    And I select from 0 to 3
    And I cut text
    And I move the cursor to 2
    And I paste text
    Then I should see "nkFra" in the edit tab

  Scenario: Paste inserts the copied text
    When I open a new edit tab
    And I replace the contents with "Frank"
    And I select from 0 to 3
    And I copy text
    And I move the cursor to 2
    And I paste text
    Then I should see "FrFraank" in the edit tab

  Scenario: Paste pastes the most recent copy
    When I open a new edit tab
    And I replace the contents with "Frank"
    And I select from 0 to 3
    And I copy text
    And I select from 3 to 5
    And I copy text
    And I move the cursor to 0
    And I paste text
    Then I should see "nkFrank" in the edit tab 