Feature: Search through a document
  As a user
  I want to be able to search within the text

  Background:
    Given there is an EditTab open
    And I have typed "astral_queen1\nastral_queen2\n"
    And I have pressed "Page_Up"
  
  Scenario: Search forward
    When I press "Ctrl+S"
    And I type "queen"
    Then I should see "<s>queen<c>1" in the EditTab
    
  Scenario: Search forward again
    When I press "Ctrl+S"
    And I type "queen"
    And I press "Ctrl+S"
    Then I should see "<s>queen<c>2" in the EditTab
    
  Scenario: Search backward
    When I press "Ctrl+S"
    And I type "queen"
    And I press "Ctrl+S"
    And I press "Super+Ctrl+S"
    Then I should see "<s>queen<c>1" in the EditTab

    
