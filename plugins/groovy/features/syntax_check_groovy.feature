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

  Scenario: If a project classpath.groovy file has syntax errors, there should be an error message and annotations
    And I close the focussed tab
    Given I have not suppressed syntax checking message dialogs
    When I will choose "plugins/groovy/features/fixtures" from the "open_directory" dialog
    And I open a directory
    And I have opened "plugins/groovy/features/fixtures/.redcar/classpath.groovy"
    And I replace the contents with "def x = 4\nsdef"
    And I save the tab
    Then I should see a message box containing "An error occurred while loading groovy classpath file"

  Scenario: If an error occurs while parsing a groovy file, there should be an error message
    Given I have not suppressed syntax checking message dialogs
    When I will choose "plugins/groovy/features/fixtures" from the "open_directory" dialog
    And I open a directory
    And I add "lib2" to the "groovy" classpath
    And I replace the contents with "class Foo {\n    def x = new Bar(10)\n    def y = new FooBaz()\n}"
    And I save the tab
    Then I should see a message box containing "An error occurred while parsing"
    And the tab should have an annotation on line 2

  Scenario: If syntax message dialogs are suppressed, I should see no message boxes
    Given I have suppressed syntax checking message dialogs
    When I will choose "plugins/groovy/features/fixtures" from the "open_directory" dialog
    And I open a directory
    And I have opened "plugins/groovy/features/fixtures/.redcar/classpath.groovy"
    And I replace the contents with "sdef"
    And I save the tab
    Then the tab should not have annotations
    When I close the focussed tab
    And I add "lib2" to the "groovy" classpath
    And I replace the contents with "class Foo {\n    def x = new Bar(10)\n    def y = new FooBaz()\n}"
    And I save the tab
    Then the tab should have an annotation on line 2
