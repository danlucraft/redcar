Feature: Syntax Checking for Mirah
  As a user
  I want to get annotations on syntax errors and warnings in Mirah files

  Background:
    When I have opened "plugins/mirah/features/fixtures/test.mirah"

  Scenario: A syntax-clean Mirah file has no syntax error annotations
    When I replace the contents with "def foo\n  bar\nend"
    And I save the tab
    And I wait 2 seconds
    Then the tab should not have annotations

  Scenario: A syntax-error in a Mirah file should cause syntax error annotations
    When I replace the contents with "def foo\n  => bar\nend"
    And I save the tab
    And I wait 2 seconds
    Then the tab should have annotations
    And the tab should have an annotation on line 2

  Scenario: A syntax-warning in a Mirah file should cause syntax warning annotations
    When I replace the contents with "def foo\n end"
    And I save the tab
    And I wait 2 seconds
    Then the tab should have annotations
    And the tab should have an annotation on line 2

  Scenario: Fixing a syntax-error in a Mirah file should cause syntax error annotations to vanish
    When I replace the contents with "def foo\n  => bar\nend"
    And I save the tab
    And I wait 2 seconds
    Then the tab should have annotations
    When I replace the contents with "def foo\n  bar\nend"
    And I save the tab
    And I wait 2 seconds
    Then the tab should not have annotations

  Scenario: Fixing a syntax-warning in a Mirah file should cause syntax error annotations to vanish
    When I replace the contents with "def foo\n end"
    And I save the tab
    And I wait 2 seconds
    Then the tab should have annotations
    When I replace the contents with "def foo\nend"
    And I save the tab
    And I wait 2 seconds
    Then the tab should not have annotations
