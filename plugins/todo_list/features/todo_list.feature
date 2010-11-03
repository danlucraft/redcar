Feature: Adding parameters to commands
  As a user
  I want to see what todo-items remain in my project

  Background:
    Given I will choose "plugins/todo_list/spec/fixtures/project" from the "open_directory" dialog
    And I open a directory
    When I open the "Todo List" from the "Project" menu
    And I wait "2" seconds

  Scenario: Opening the TODO list shows the todo items and their action texts without colons
    Then the HTML tab should say "a course of action"
    And the HTML tab should not say ": a course of action"

  Scenario: Opening the TODO list shows the todo item's file names
    Then the HTML tab should say "OPTIMIZE_colon.file"
    And the HTML tab should say "FIXME.file"

  Scenario: Opening the TODO list shows the todo item's line numbers
    Then the HTML tab should say "OPTIMIZE_colon.file:1"
    And the HTML tab should say "FIXME.file:3"

  Scenario: Clicking a TODO item's file name should open it in an edit tab
    When I click "FIXME.file" in the HTML tab
    Then my active tab should be "FIXME.file"
    And the contents should be "#\n#\n<c># FIXME note"
