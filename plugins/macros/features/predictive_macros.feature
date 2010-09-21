Feature: Predictive macros
  As a user
  I want Redcar to read my mind
  So I don't have to type stuff

  Background:
    When I open a new edit tab

  Scenario: Repeat simple command sequence that is fully repeated
    When I type "abab"
    And I press predict
    Then the contents should be "ababab"
    
  Scenario: Repeat simple command sequence that is fully repeated twice
    When I type "abab"
    And I press predict
    And I press predict
    Then the contents should be "abababab"

  Scenario: Repeat simple command sequence that is partially repeated
    When I type "aba"
    And I press predict
    Then the contents should be "abab"
    