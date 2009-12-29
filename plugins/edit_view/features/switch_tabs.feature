Feature: Switch and move tabs within a notebook

  Scenario: Switch tab down
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab
    And I replace the contents with "Elizabeth Woodville"
    Then I should see "Elizabeth Woodville" in the edit tab
    And I move down a tab
    Then I should see "Anne Boleyn" in the edit tab

  Scenario: Switch tab down too far
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab
    And I replace the contents with "Elizabeth Woodville"
    Then I should see "Elizabeth Woodville" in the edit tab
    And I move down a tab
    And I move down a tab
    Then I should see "Anne Boleyn" in the edit tab

  Scenario: Switch tab up
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab
    And I replace the contents with "Elizabeth Woodville"
    Then I should see "Elizabeth Woodville" in the edit tab
    And I move down a tab
    And I move up a tab
    Then I should see "Elizabeth Woodville" in the edit tab
    
  Scenario: Switch tab up too far
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I open a new edit tab
    And I replace the contents with "Elizabeth Woodville"
    Then I should see "Elizabeth Woodville" in the edit tab
    And I move up a tab
    Then I should see "Elizabeth Woodville" in the edit tab
  
  Scenario: Switch notebooks
    When I open a new edit tab
    And I replace the contents with "Anne Boleyn"
    And I make a new notebook
    When I open a new edit tab
    And I replace the contents with "Scarlett"
    And I move the tab to the other notebook
    When I switch notebooks
    Then I should see "Anne Boleyn" in the edit tab
    
    
    
    
    
  