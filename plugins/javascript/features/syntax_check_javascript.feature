Feature: Syntax Checking for JavaScript
  As a user
  I want to get annotations on syntax errors in JavaScript files
  # 
  # Background:
  #   When I have opened "plugins/javascript/features/fixtures/test.js"
  # 
  # Scenario: A syntax-clean JavaScript file has no syntax error annotations
  #   When I replace the contents with "var foo = 1;"
  #   And I save the tab
  #   Then the tab should not have annotations
  # 
  # Scenario: A syntax-error in a JavaScript file should cause syntax error annotations
  #   When I replace the contents with "var foo = 1;\nbar"
  #   And I save the tab
  #   And I wait 2 seconds
  #   Then the tab should have annotations
  #   And the tab should have an annotation on line 2
  # 
  # Scenario: Fixing a syntax-error in a JavaScript file should cause syntax error annotations to vanish
  #   When I replace the contents with "var foo = 1;\nbar"
  #   And I save the tab
  #   And I wait 2 seconds
  #   Then the tab should have annotations
  #   When I replace the contents with "var foo = 1;\nvar bar;"
  #   And I save the tab
  #   Then the tab should not have annotations
  # 
  # Scenario: Checking for syntax errors on a file with syntax errors should not cause concurrency errors
  #   When I replace the contents with "foo\nbar\nfunction\nbax\nboo\nbonne"
  #   And I save the tab 10 times and wait 2 seconds each time
  #   Then the tab should not have thrown SWT concurrency exceptions
  # 
  # Scenario: Checking for syntax errors between two different error-throwing files should not cause concurrency errors
  #   When I replace the contents with "foo\nbar\nfunction\nbax\nboo\nbonne"
  #   And I have opened "plugins/javascript/features/fixtures/test2.js"
  #   And I replace the contents with "boo foo\nbaz\nbee\nbaux\nbeau"
  #   And I save the tab
  #   And I wait 1 seconds
  #   And I switch up a tab
  #   And I save the tab
  #   And I wait 1 seconds
  #   And I switch down a tab
  #   And I save the tab
  #   And I wait 1 seconds
  #   And I switch up a tab
  #   And I save the tab
  #   And I wait 1 seconds
  #   Then the tab should not have thrown SWT concurrency exceptions
  #   And the tab should have annotations
  #   When I switch down a tab
  #   Then the tab should have annotations
  # 
  # Scenario: Checking rapidly for syntax errors between two files should not cause concurrency errors
  #   When I replace the contents with "foo\nbar\nfunction\nbax\nboo\nbonne"
  #   And I have opened "plugins/javascript/features/fixtures/test2.js"
  #   And I replace the contents with "boo foo\nbaz\nbee\nbaux\nbeau"
  #   And I save the tab
  #   And I switch up a tab
  #   And I save the tab
  #   And I switch down a tab
  #   And I save the tab
  #   And I switch up a tab
  #   And I save the tab
  #   And I wait 5 seconds
  #   Then the tab should not have thrown SWT concurrency exceptions
  #   And the tab should have annotations
  #   When I switch down a tab
  #   Then the tab should have annotations
  # 
