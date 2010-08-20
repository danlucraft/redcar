Feature: Running commands in a tab

  Background:
    When I will choose "plugins/runnables/features/fixtures" from the "open_directory" dialog
    And I open a directory

  Scenario: Running a command from the tree
    When I open the runnables tree
    And I expand the tree row "fixture_runnables"
    And I activate the "An app" node in the tree
    Then my active tab should be "An app"
    And the HTML tab should say "hello world"
    
  Scenario: Running a command based on a file name
    Given I have opened "plugins/runnables/features/fixtures/runnable_app.rb"
    And I run the command Redcar::Runnables::RunEditTabCommand
    Then my active tab should be "Running runnable_app.rb"
    And the HTML tab should say "hello world"

  Scenario: Running a command without output

  Scenario: Running a command with windowed output
