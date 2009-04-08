Feature: Manage tabs
  As a user
  I want to be able to manage tabs within the Redcar window
  So that I can do lots of things at once

  Scenario: Change tab down
    Given there are TestTabs open "A, B"
    And I am looking at TestTab "A"
    And I press "Ctrl+Page_Down"
    Then I should be looking at the second EditTab
    And I should be looking at TestTab "B"

  Scenario: Move Tab Down
    Given there are TestTabs open "A, B"
    And I am looking at TestTab "A"
    And I press "Ctrl+Shift+Page_Down"
    Then I should be looking at the second EditTab
    And I should be looking at TestTab "A"
   
  Scenario: Change tab up
    Given there are TestTabs open "A, B"
    And I am looking at TestTab "B"
    And I press "Ctrl+Page_Up"
    Then I should be looking at the first EditTab
    And I should be looking at TestTab "A"

  Scenario: Move Tab Up
    Given there are TestTabs open "A, B"
    And I am looking at TestTab "B"
    And I press "Ctrl+Shift+Page_Up"
    Then I should be looking at the first EditTab
    And I should be looking at TestTab "B"
    
    
