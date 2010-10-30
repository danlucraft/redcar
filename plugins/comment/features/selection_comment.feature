Feature: Commenting a selected area of text

  Background:
    When I open a new edit tab

  Scenario: Commenting a part of a line
    When I replace the contents with "a piece of code"
    And I switch the language to "Java"
    And I toggle block comment
    Then I should see "/*a piece of code*/" in the edit tab
    When I toggle block comment
    Then I should see "a piece of code" in the edit tab

  Scenario: Commenting a selection spanning several lines
    When I replace the contents with "a piece\nof code"
    And I switch the language to "C++"
    And I select from 4 to 9
    And I toggle block comment
    Then I should see "a pi/*ece\no*/f code" in the edit tab
    And I toggle block comment
    Then I should see "a piece\nof code" in the edit tab
