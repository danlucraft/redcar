Feature: Opening and closing tabs
  
Scenario: Open an EditTab
  When I press "Super+N"
  And I wait for all GUI events to be processed
  Then there should be 1 tab open
