Feature: Syntax Checking for Java
  As a user
  I want to get annotations on syntax errors in Java files

  Background:
    When I have opened "plugins/java/features/fixtures/test.java"

  Scenario: A syntax-clean Java file has no syntax error annotations
    When I replace the contents with "class Foo {\n\n}"
    And I save the tab
    Then the tab should not have annotations

  Scenario: A syntax-error in a Java file should cause syntax error annotations
    When I replace the contents with "class Foo {\n    int\n}"
    And I save the tab
    And I wait "2.5" seconds
    Then the tab should have annotations
    And the tab should have an annotation on line 2

  Scenario: Fixing a syntax-error in a Java file should cause syntax error annotations to vanish
    When I replace the contents with "class Foo {\n    int\n}"
    And I save the tab
    And I wait "2.5" seconds
    Then the tab should have annotations
    When I replace the contents with "class Foo {\n\n}"
    And I wait "2.5" seconds
    And I save the tab
    Then the tab should not have annotations

  Scenario: If java is excluded from being checked, I should see no syntax errors
    Given I excluded "java" files from being checked for syntax errors
    When I replace the contents with "class Foo {\n    int\n}"
    And I save the tab
    And I wait "2.5" seconds
    Then the tab should not have annotations

  Scenario: A file which references unknown java classes should cause syntax error annotations
    And I replace the contents with "class Foo {\n    Bar x = new Bar(10);\n    FooBar y = new FooBar();\n}"
    And I save the tab
    And I wait "2.5" seconds
    Then the tab should have annotations
    And the tab should have an annotation on line 2

  Scenario: A project can add libraries and compiled class directories to the java classpath
    When I will choose "plugins/java/features/fixtures" from the "open_directory" dialog
    And I open a directory
    And I replace the contents with "class Foo {\n    Bar x = new Bar(10);\n    FooBar y = new FooBar();\n}"
    And I save the tab
    And I wait "2.5" seconds
    Then the tab should not have annotations

  Scenario: If a project classpath.java file has syntax errors, there should be an error message and annotations
    And I close the focussed tab
    Given I have not suppressed syntax checking message dialogs
    When I will choose "plugins/java/features/fixtures" from the "open_directory" dialog
    And I open a directory
    And I have opened "plugins/java/features/fixtures/.redcar/classpath.groovy"
    And I replace the contents with "def x = 4\nsdef"
    And I save the tab
    Then I should see a message box containing "An error occurred while loading classpath file"

  Scenario: If an error occurs while parsing a java file, there should be an error message
    Given I have not suppressed syntax checking message dialogs
    When I will choose "plugins/java/features/fixtures" from the "open_directory" dialog
    And I open a directory
    And I add "lib2" to the "java" classpath
    And I replace the contents with "class Foo {\n    Bar x = new Bar(10);\n    FooBaz y = new FooBaz();\n}"
    And I save the tab
    Then I should see a message box containing "An error occurred while parsing"
    And the tab should not have annotations

  Scenario: If syntax message dialogs are suppressed, I should see no message boxes
    Given I have suppressed syntax checking message dialogs
    When I will choose "plugins/java/features/fixtures" from the "open_directory" dialog
    And I open a directory
    And I have opened "plugins/java/features/fixtures/.redcar/classpath.groovy"
    And I replace the contents with "sdef"
    And I save the tab
    And I wait "2.5" seconds
    Then the tab should not have annotations
    When I close the focussed tab
    And I add "lib2" to the "java" classpath
    And I replace the contents with "class Foo {\n    Bar x = new Bar(10);\n    FooBaz y = new FooBaz();\n}"
    And I save the tab
    And I wait "2.5" seconds
    And the tab should have annotations
