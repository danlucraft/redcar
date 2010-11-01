Feature: Syntax Checking for Groovy
  As a user
  I want to get annotations on syntax errors in Groovy files

  Background:
    When I have opened "plugins/groovy/features/fixtures/test.groovy"

  Scenario: A syntax-clean Groovy file has no syntax error annotations
    When I replace the contents with "class Foo {\n\n}"
    And I save the tab
    Then the tab should not have annotations

  Scenario: A syntax-error in a Groovy file should cause syntax error annotations
    When I replace the contents with "class Foo {\n    sdef\n}"
    And I save the tab
    Then the tab should have annotations
    And the tab should have an annotation on line 2

  Scenario: Fixing a syntax-error in a Groovy file should cause syntax error annotations to vanish
    When I replace the contents with "class Foo {\n    sdef\n}"
    And I save the tab
    Then the tab should have annotations
    When I replace the contents with "class Foo {\n\n}"
    And I save the tab
    Then the tab should not have annotations
    
  Scenario: A file which references unknown groovy classes should cause syntax error annotations
    And I replace the contents with "class Foo {\n    def x = new Bar(10)\n    def y = new FooBar()\n}"
    And I save the tab
    Then the tab should have annotations
    And the tab should have an annotation on line 2
    
  Scenario: A project can add libraries and compiled class directories to the groovy classpath
    When I will choose "plugins/groovy/features/fixtures" from the "open_directory" dialog
    And I open a directory
    And I replace the contents with "class Foo {\n    def x = new Bar(10)\n    def y = new FooBar()\n}"
    And I save the tab
    Then the tab should not have annotations