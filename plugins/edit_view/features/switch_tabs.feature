Feature: Switch and move tabs within a notebook

  Scenario: Switch tab down
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab
    And I replace the contents with "Elizabeth Woodville"
    Then I should see "Elizabeth Woodville" in the edit tab
    And I switch down a tab
    Then I should see "Anne Boleyn" in the edit tab

  Scenario: Switching tabs down will wrap
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab
    And I replace the contents with "Elizabeth Woodville"
    Then I should see "Elizabeth Woodville" in the edit tab
    And I switch down a tab
    And I switch down a tab
    Then I should see "Elizabeth Woodville" in the edit tab

  Scenario: Switch tab up
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab
    And I replace the contents with "Elizabeth Woodville"
    Then I should see "Elizabeth Woodville" in the edit tab
    And I switch down a tab
    And I switch up a tab
    Then I should see "Elizabeth Woodville" in the edit tab
    
  Scenario: Switching tabs up will wrap
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab
    And I replace the contents with "Elizabeth Woodville"
    Then I should see "Elizabeth Woodville" in the edit tab
    And I switch up a tab
    Then I should see "Anne Boleyn" in the edit tab
  
  Scenario: Switch notebooks
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I make a new notebook
    When I open a new edit tab
    And I replace the contents with "Scarlett"
    And I move the tab to the other notebook
    When I switch notebooks
    Then I should see "Anne Boleyn" in the edit tab
    
  Scenario: Move tab up
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab
    And I replace the contents with "Elizabeth Woodville"
    Then I should see "Elizabeth Woodville" in the edit tab
    And I switch down a tab
    Then I should see "Anne Boleyn" in the edit tab
    And I move up a tab
    Then I should see "Anne Boleyn" in the edit tab
    And I switch down a tab
    Then I should see "Elizabeth Woodville" in the edit tab
    
    
  Scenario: Moving tabs up will wrap
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab
    And I replace the contents with "Elizabeth Woodville"
    And I open a new edit tab
    And I replace the contents with "Catherine of Aragon"
    Then I should see "Catherine of Aragon" in the edit tab
    And I move up a tab
    And I move up a tab
    And I move up a tab
    And I move up a tab
    And I switch up a tab
    Then I should see "Anne Boleyn" in the edit tab
    
  Scenario: Move tab down
    When I open a new edit tab titled "Anne"
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab titled "Betty"
    And I replace the contents with "Elizabeth Woodville"
    Then I should see "Elizabeth Woodville" in the edit tab
    And I move down a tab
    Then I should see "Elizabeth Woodville" in the edit tab
    And I switch up a tab
    Then I should see "Anne Boleyn" in the edit tab
    
  Scenario: Moving tabs down will wrap
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab
    And I replace the contents with "Elizabeth Woodville"
    And I open a new edit tab
    And I replace the contents with "Catherine of Aragon"
    Then I should see "Catherine of Aragon" in the edit tab
    And I move down a tab
    And I move down a tab
    And I move down a tab
    And I move down a tab
    And I switch down a tab
    Then I should see "Anne Boleyn" in the edit tab
    
  