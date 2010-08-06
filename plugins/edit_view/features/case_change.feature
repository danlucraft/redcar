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
    Then the contents should be "Curry CHIC<c>KEN"

  Scenario: Downcase text
    When I replace the contents with "CURRY CHICKEN"
    And I select from 0 to 5
    And I run the command Redcar::EditView::DowncaseTextCommand
    Then the contents should be "curry CHICKEN"

  Scenario: Titlize text
    When I replace the contents with "curry chicken"
    And I select from 0 to 13
    And I run the command Redcar::EditView::TitlizeTextCommand
    Then the contents should be "Curry Chicken"
  
  Scenario: Opposite case
    When I replace the contents with "Curry Chicken"
    And I select from 0 to 13
    And I run the command Redcar::EditView::OppositeCaseTextCommand
    Then the contents should be "cURRY cHICKEN"
  
  Scenario: Camel case
    When I replace the contents with "curry_chicken"
    And I move the cursor to 13
    And I run the command Redcar::EditView::CamelCaseTextCommand
    Then the contents should be "CurryChicken<c>"
  
  Scenario: Underscore
    When I replace the contents with "CurryChicken"
    And I move the cursor to 12
    And I run the command Redcar::EditView::UnderscoreTextCommand
    Then the contents should be "curry_chicken"
    
  Scenario: Pascal to Underscore to Camel Case rotation
    When I replace the contents with "CurryChicken"
    And I move the cursor to 12
    And I run the command Redcar::EditView::CamelSnakePascalRotateTextCommand
    Then the contents should be "curry_chicken"
    When I run the command Redcar::EditView::CamelSnakePascalRotateTextCommand
    Then the contents should be "curryChicken"
    When I run the command Redcar::EditView::CamelSnakePascalRotateTextCommand
    Then the contents should be "CurryChicken<c>"
  