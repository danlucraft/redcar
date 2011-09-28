Feature: Cut and Paste

  Background: 
    When I open a new edit tab

  Scenario: Cut removes the text
    When I replace the contents with "Frank"
    And I select 3 from (0,0)
    And I cut text
    Then I should not see "Fra" in the edit tab  
    And I should see "nk" in the edit tab  

  Scenario: Copy leaves the text
    When I replace the contents with "Frank"
    And I select 3 from (0,0)
    And I copy text
    Then I should see "Frank" in the edit tab  

  Scenario: Paste inserts the cut text
    When I replace the contents with "Frank"
    And I select 3 from (0,0)
    And I cut text
    And I move the cursor to (0,2)
    And I paste text
    Then the contents should be "nkFra<c>"

  Scenario: Paste inserts the copied text
    When I replace the contents with "Frank"
    And I select 3 from (0,0)
    And I copy text
    And I move the cursor to (0,2)
    And I paste text
    Then I should see "FrFraank" in the edit tab
    Then the contents should be "FrFra<c>ank"

  Scenario: Paste pastes the most recent copy
    When I replace the contents with "Frank"
    And I select 3 from (0,0)
    And I copy text
    And I select 2 from (0,3)
    And I copy text
    And I move the cursor to (0,0)
    And I paste text
    Then the contents should be "nk<c>Frank"
 