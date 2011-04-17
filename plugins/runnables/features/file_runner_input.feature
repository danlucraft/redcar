@runnables
Feature: Using file properties in commands
  As a user
  I want to run commands that rely on the current edit view
  So I don't have to write many similar commands

  Background:
    When I will choose "plugins/runnables/features/fixtures" from the "open_directory" dialog
    And I open a directory

  Scenario: Using the name of the current file in a command
    Given I have opened "plugins/runnables/features/fixtures/name_app.rb"
    And I run the command Redcar::Runnables::RunEditTabCommand
    Then my active tab should be "Running name_app.rb"
    And the HTML tab should say "name_app"

  Scenario: Using the current line number in a command
    Given I have opened "plugins/runnables/features/fixtures/line_app.rb"
    And I run the command Redcar::Runnables::RunEditTabCommand
    Then my active tab should be "Running line_app.rb"
    And the HTML tab should say "1"