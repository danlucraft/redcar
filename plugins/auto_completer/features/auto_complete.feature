Feature: Auto Complete

  Scenario: Autocomplete with no completions
    When I open a new edit tab
    And I replace the contents with "Tess"
    And I move the cursor to (0,4)
    And I auto-complete
    Then I should see "Tess" in the edit tab

  Scenario: Autocomplete with one completions
    When I open a new edit tab
    And I replace the contents with "Daly Da"
    And I move the cursor to (0,7)
    And I auto-complete
    Then I should see "Daly Daly" in the edit tab

  Scenario: Autocomplete with one completions, twice
    When I open a new edit tab
    And I replace the contents with "Daly Da"
    And I move the cursor to (0,7)
    And I auto-complete
    And I auto-complete
    Then I should see "Daly Da" in the edit tab
    And I should not see "Daly Daly" in the edit tab

  Scenario: Autocomplete with two completions
    When I open a new edit tab
    And I replace the contents with "Dan Daly Da"
    And I move the cursor to (0,11)
    And I auto-complete
    Then I should see "Dan Daly Daly" in the edit tab

  Scenario: Autocomplete with two completions, twice
    When I open a new edit tab
    And I replace the contents with "Dan Daly Da"
    And I move the cursor to (0,11)
    And I auto-complete
    And I auto-complete
    Then I should see "Dan Daly Dan" in the edit tab

  Scenario: Autocomplete with two completions, thrice
    When I open a new edit tab
    And I replace the contents with "Dan Daly Da"
    And I move the cursor to (0,11)
    And I auto-complete
    And I auto-complete
    And I auto-complete
    Then I should see "Dan Daly Da" in the edit tab
    And I should not see "Dan Daly Daly" in the edit tab
    And I should not see "Dan Daly Dan" in the edit tab
    
  Scenario: Autocomplete at the start of a word
    When I open a new edit tab
    And I replace the contents with "Da Daly Dan"
    And I auto-complete
    Then I should see "Da Daly Dan" in the edit tab

  Scenario: Autocomplete with one completions at the end of a line
    When I open a new edit tab
    And I replace the contents with "Daly Da\nfoo"
    And I move the cursor to (0,7)
    And I auto-complete
    Then I should see "Daly Daly\nfoo" in the edit tab


