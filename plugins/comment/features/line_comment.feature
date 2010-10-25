Feature: Commenting lines by prefixing a comment string

  Background:
    Given insert single space after comment is disabled
    When I open a new edit tab

  Scenario: Commenting a single line
    When I replace the contents with "A piece of code"
    And I switch the language to "C"
    And I toggle comment lines
    Then I should see "//A piece of code" in the edit tab
    When I toggle comment lines
    Then I should see "A piece of code" in the edit tab

  Scenario: Commenting several lines
    When I replace the contents with "Two pieces\nof code"
    And I switch the language to "Ruby"
    And I select from 0 to 12
    And I toggle comment lines
    Then I should see "#Two pieces\n#of code" in the edit tab
    When I toggle comment lines
    Then I should see "Two pieces\nof code" in the edit tab

  Scenario: Inserting a single space after comments when a line has no indentation
    Given insert single space after comment is enabled
    When I replace the contents with "A few\nlines\nof unindented\ncode"
    And I switch the language to "Ruby"
    And I select from 1 to 27
    And I toggle comment lines
    Then I should see "# A few\n# lines\n# of unindented\n# code" in the edit tab
    When I toggle comment lines
    Then I should see "A few\nlines\nof unindented\ncode" in the edit tab