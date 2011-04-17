@runnables
Feature: Running an alternate file runner
  As a user
  I want to run tabs in different ways
  So I need a separate terminal less often

  Background:
    When I will choose "plugins/runnables/features/fixtures" from the "open_directory" dialog
    And I open a directory

  Scenario: Getting the second match from a list of file runners
    Given I have opened "plugins/runnables/features/fixtures/alternate.ruby"
    And I run the command Redcar::Runnables::RunAlternateEditTabCommand
    Then my active tab should be "Running alternate.ruby"
    And the HTML tab should say "hello world"
