Feature: Undo and Redo

  Scenario: Commands are inactive for a new tab
    When I open a new edit tab
    Then the menu item "Edit|Undo" should be inactive
    And the menu item "Edit|Redo" should be inactive
  
  Scenario: Undo becomes active when I type something
    When I open a new edit tab
    And I replace the contents with "Bolzano"
    Then the menu item "Edit|Undo" should be active
    And the menu item "Edit|Redo" should be inactive
    
  Scenario: Undo undoes typing
    When I open a new edit tab
    And I replace the contents with "Bolzano"
    And I undo
    Then I should not see "Bolzano" in the edit tab

  Scenario: Undo undoes typing twice
    When I open a new edit tab
    And I replace the contents with "Bolzano"
    And I replace the contents with "Weierstrass"
    And I undo
    Then I should not see "Weierstrass" in the edit tab
    And I should see "Bolzano" in the edit tab
    And I undo
    Then I should not see "Weierstrass" in the edit tab
    And I should not see "Bolzano" in the edit tab

  Scenario: Undo becomes inactive and redo active when I undo everything
    When I open a new edit tab
    And I replace the contents with "Bolzano"
    And I undo
    Then the menu item "Edit|Undo" should be inactive
    And the menu item "Edit|Redo" should be active
    
  Scenario: Redo redoes typing
    When I open a new edit tab
    And I replace the contents with "Bolzano"
    And I undo
    And I redo
    And I should see "Bolzano" in the edit tab
    
  Scenario: Redo becomes inactive when I redo everything
    When I open a new edit tab
    And I replace the contents with "Bolzano"
    And I undo
    And I redo
    Then the menu item "Edit|Undo" should be active
    And the menu item "Edit|Redo" should be inactive
    