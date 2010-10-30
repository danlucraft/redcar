Feature: Adding parameters to commands
  As a user
  I want to see what todo-items remain in my project

  Background:
    Given I will choose "plugins/todo_list/spec/fixtures/project" from the "open_directory" dialog
    And I open a directory

  Scenario: Opening the TODO list shows the todo items and their action texts without colons
    When I open the "Todo List" from the "Project" menu
    Then my active tab should be "Todo List"
    And the HTML tab should say "/project/OPTIMIZE_colon.file"
    And the HTML tab should say "a course of action"
    And the HTML tab should not say ": a course of action"

