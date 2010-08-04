Feature: Change Case

  Background:
    When I open a new edit tab

  Scenario: Upcase text
    When I replace the contents with "Curry Chicken"
    And I select from 0 to 5
    And I run the command Redcar::EditView::UpcaseTextCommand
    Then the contents should be "CURRY Chicken"

  Scenario: Upcase word if no selection
    When I replace the contents with "Curry Chicken"
    And I move the cursor to 10
    And I run the command Redcar::EditView::UpcaseTextCommand
    Then the contents should be "Curry CHICKEN"
