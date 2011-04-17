@runnables
Feature: Adding parameters to commands
  As a user
  I want to add parameters to commands
  So I don't need to make many similar ones

  Background:
    When I will choose "plugins/runnables/features/fixtures" from the "open_directory" dialog
    And I open a directory

  Scenario: Running a command containing parameters
    Given I would type "runnable_app.rb" in an input box
    When I open the runnables tree
    And I expand the tree row "fixture_runnables"
    And I activate the "A params app" node in the tree
    Then my active tab should be "A params app"
    And the HTML tab should say "hello world"

  Scenario: Running a command containing parameters
    Given I would type "hello" in an input box
    And I would type "world" in an input box
    When I open the runnables tree
    And I expand the tree row "fixture_runnables"
    And I activate the "A multi-params app" node in the tree
    Then my active tab should be "A multi-params app"
    And the HTML tab should say "hello world"

  Scenario: Appending parameters before running a command
    Given I would type "world" in an input box
    When I open the runnables tree
    And I expand the tree row "fixture_runnables"
    And I append parameters to the "An appendable app" node in the tree
    Then my active tab should be "An appendable app"
    And the HTML tab should say "hello world"

  Scenario: Appending parameters to a command which ends in parameters is disallowed
    Given I would type "runnable_app.rb" in an input box
    And I would type "there" in an input box
    When I open the runnables tree
    And I expand the tree row "fixture_runnables"
    And I append parameters to the "A params app" node in the tree
    Then my active tab should be "A params app"
    And the HTML tab should say "hello world"