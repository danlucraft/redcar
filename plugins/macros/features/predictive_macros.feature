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
    
  Scenario: Should continue repeating same prediction even if a longer pattern is spotted
    When I type "abab"
    And I press predict
    And I press predict
    And I press predict
    Then the contents should be "ababababab"

  Scenario: Can define a new pattern after repeating
    When I type "abab"
    And I press predict
    When I type "cdcd"
    And I press predict
    Then the contents should be "abababcdcdcd"
  
  Scenario: Can change prediction
    When I type "abccabcc"
    And I press predict
    Then the contents should be "abccabccabcc"
    When I press alternate predict
    Then the contents should be "abccabccc"
  
  Scenario: Shouldn't raise an error when there are no predictions
    When I type "abc"
    And I press predict
    Then the contents should be "abc"
    
  Scenario: Commenting example with full repeat
    Given I replace the contents with "foo\nbar\nbaz\nqux\nquux\ncorge"
    And I move the cursor to 0
    And I type "# "
    And I move down
    And I move left
    And I move left
    And I type "# "
    And I move down
    And I move left
    And I move left
    And I press predict
    And I press predict
    Then the contents should be "# foo\n# bar\n# baz\n# qux\n<c>quux\ncorge"
    
  Scenario: Commenting example with partial repeat
    Given I replace the contents with "foo\nbar\nbaz\nqux\nquux\ncorge"
    And I move the cursor to 0
    And I type "# "
    And I move down
    And I move left
    And I move left
    And I type "# "
    And I press predict
    And I press predict
    Then the contents should be "# foo\n# bar\n# baz\n<c>qux\nquux\ncorge"
    

    