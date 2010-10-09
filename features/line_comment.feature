Feature: Commenting lines by prefixing a comment string

  Background:
    When I open a new edit tab

  Scenario: Commenting a single line
    When I replace the contents with "A piece of code"
    And I switch the language to "C"
    And I toggle comment lines
    Then I should see "//A piece of code" in the edit tab

  Scenario: Commenting several lines
    When I replace the contents with "Two pieces\nof code"
    And I switch the language to "Ruby"
    And I select from 0 to 12
    And I toggle comment lines
    Then I should see "#Two pieces\n#of code" in the edit tab

  Scenario: Uncommenting a single line
    When I replace the contents with "//A piece of code"
    And I switch the language to "C"
    And I toggle comment lines
    Then I should see "A piece of code" in the edit tab

  Scenario: Uncommenting several lines
    When I replace the contents with "#Two pieces\n#of code"
    And I switch the language to "Ruby"
    And I select from 0 to 12
    And I toggle comment lines
    Then I should see "Two pieces\nof code" in the edit tab