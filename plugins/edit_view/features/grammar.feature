Feature: Grammar

  Scenario: Changing languages should change behaviour of word matching
    When I open a new edit tab
    And I replace the contents with "Who let the dogs out?"
    And I switch the language to "C++"
    And I select the word at 18
    Then the selected text should be "out"
    And I switch the language to "Ruby"
    And I select the word at 18
    Then the selected text should be "out?"