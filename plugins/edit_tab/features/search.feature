Feature: Search through a document
  As a user
  I want to be able to search within the text

  Background:
    Given there is an EditTab open
    And I have typed "astral_queen1\nastral_queen2\n"
    And I have pressed "Page_Up"
  
  Scenario: Find forward
    When I press "Super+F"
    And I type "queen"
    And I press "Return"
    Then I should see "<s>queen<c>1" in the EditTab
    
  Scenario: Find forward twice
    When I press "Super+F"
    And I type "queen"
    And I press "Return" then "Return"
    Then I should see "<s>queen<c>2" in the EditTab

  Scenario: Find forward many times
    When I press "Super+F"
    And I type "queen"
    And I press "Return" then "Return"
    And I press "Return" then "Return"
    Then I should see "<s>queen<c>2" in the EditTab
    
  Scenario: Wrap around
    When I press "Super+F"
    And I type "queen"
    And I press "Ctrl+Space" then "Return"
    And I press "Return" then "Return"
    Then I should see "<s>queen<c>1" in the EditTab
    
  Scenario: Incremental Search forward
    When I press "Super+S"
    And I type "queen"
    Then I should see "<s>queen<c>1" in the EditTab
    
  Scenario: Incremental Search forward again
    When I press "Super+S"
    And I type "queen"
    And I press "Super+S"
    Then I should see "<s>queen<c>2" in the EditTab
    
  Scenario: Incremental Search backward
    When I press "Super+S"
    And I type "queen"
    And I press "Super+S"
    And I press "Super+Shift+S"
    Then I should see "<s>queen<c>1" in the EditTab

    
