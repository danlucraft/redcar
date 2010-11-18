Feature: Syntax Checking for JavaScript
  As a user
  I want to get annotations on syntax errors in JavaScript files

  Background:
    When I have opened "plugins/javascript/features/fixtures/test.js"

  Scenario: A syntax-clean JavaScript file has no syntax error annotations
    When I replace the contents with "var foo = 1;"
    And I save the tab
    Then the tab should not have annotations

  Scenario: A syntax-error in a JavaScript file should cause syntax error annotations
    When I replace the contents with "var foo = 1;\nbar"
    And I save the tab
    And I wait "1.5" seconds
    Then the tab should have annotations
    And the tab should have an annotation on line 2

  Scenario: Fixing a syntax-error in a JavaScript file should cause syntax error annotations to vanish
    When I replace the contents with "var foo = 1;\nbar"
    And I save the tab
    And I wait "1.5" seconds
    Then the tab should have annotations
    When I replace the contents with "var foo = 1;\nvar bar;"
    And I save the tab
    Then the tab should not have annotations