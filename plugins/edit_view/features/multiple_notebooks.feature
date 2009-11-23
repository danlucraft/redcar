# This is in this plugin because it is important and easier to test the EditTab
Feature: Multiple notebooks

  Scenario: Begins with one notebook
    Then there should be one notebook

  Scenario: New notebooks
    When I make a new notebook
    Then there should be two notebooks
  
  Scenario: Open tabs stay in the first notebook
    When I open a new edit tab
    And I make a new notebook
    Then there should be two notebooks
    And notebook 1 should have 1 tab
    And notebook 2 should have 0 tabs
  
  Scenario: First notebook remains focussed
    When I make a new notebook
    And I open a new edit tab
    Then there should be two notebooks
    And notebook 1 should have 1 tab
    And notebook 2 should have 0 tabs

  @wip
  Scenario: Can move a tab to another notebook
    When I open a new edit tab
    And I make a new notebook
    And I move the tab to the other notebook
    Then notebook 1 should have 0 tabs
    And notebook 2 should have 1 tab
    
  
  
    
  
