Feature: Syntax Checking for Ruby
  As a user
  I want to get annotations on syntax errors in Ruby files

  Background:
    When I have opened "plugins/ruby/features/fixtures/test.rb"

  Scenario: A syntax-clean Ruby file has no syntax error annotations
    When I replace the contents with "def foo\n  bar\nend"
    And I save the tab
    Then the tab should not have annotations
    And the file "plugins/ruby/features/fixtures/test.rb" should be deletable

  Scenario: A syntax-error in a Ruby file should cause syntax error annotations
    When I replace the contents with "def foo\n  => bar\nend"
    And I save the tab
    Then the tab should have annotations
    And the tab should have an annotation on line 2

  Scenario: Fixing a syntax-error in a Ruby file should cause syntax error annotations to vanish
    When I replace the contents with "def foo\n  => bar\nend"
    And I save the tab
    Then the tab should have annotations
    When I replace the contents with "def foo\n  bar\nend"
    And I save the tab
    Then the tab should not have annotations
