Feature: Cut and Paste

  Scenario: Commands are inactive for a new tab
    When I open a new edit tab
    Then the menu item "Edit|Cut" should be inactive
    And the menu item "Edit|Copy" should be inactive
    And the menu item "Edit|Paste" should be inactive
  
  Scenario: Cut and copy are active when there is selected text
    When I open a new edit tab
    And I replace the contents with "Frank"
    And I select from 0 to 3
    Then the menu item "Edit|Cut" should be active
    And the menu item "Edit|Copy" should be active
    And the menu item "Edit|Paste" should be inactive
  
  Scenario: Paste is active once I've copied something
    When I open a new edit tab
    And I replace the contents with "Frank"
    And I select from 0 to 3
    And I copy text
    Then the menu item "Edit|Cut" should be active
    And the menu item "Edit|Copy" should be active
    And the menu item "Edit|Paste" should be active

  Scenario: Paste is active once I've cut something
    When I open a new edit tab
    And I replace the contents with "Frank"
    And I select from 0 to 3
    And I cut text
    Then the menu item "Edit|Cut" should be inactive
    And the menu item "Edit|Copy" should be inactive
    And the menu item "Edit|Paste" should be active
  
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