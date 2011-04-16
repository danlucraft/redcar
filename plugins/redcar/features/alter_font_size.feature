@reset-font-size
Feature: The font size can be increased and decreased within bounds

  Background:
    Given I open a new edit tab
    And I replace the contents with "Hello! Hello! Hello!"

  Scenario: The font size can be increased until it reaches maximum size
    When I set the font size to 14
    Then the font size should be 14
    And I increase the font size
    Then the font size should be 15
    When I set the font size to maximum
    And I increase the font size
    And I increase the font size
    Then the font size should be maximum

  Scenario: The font size can be decreased until it reaches minimum size
    When I set the font size to 21
    Then the font size should be 21
    And I decrease the font size
    Then the font size should be 20
    When I set the font size to minimum
    And I decrease the font size
    And I decrease the font size
    Then the font size should be minimum