Feature: Opening and closing tabs
  
Scenario: Open an EditTab
  When I press "Super+N"
  Then there should be 1 EditTab open
