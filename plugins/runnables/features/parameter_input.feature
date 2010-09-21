Feature: Adding parameters to commands

Scenario: Running a command containing parameters
  Given I will set "runnable_app.rb" as a parameter
  When I open the runnables tree
  And I expand the tree row "fixture_runnables"
  And I activate the "A params app" node in the tree
  Then my active tab should be "A params app"
  And the HTML tab should say "hello world"

Scenario: Running a command containing parameters
  Given I will set "hello" as a parameter
  And I will set "world" as a parameter
  When I open the runnables tree
  And I expand the tree row "fixture_runnables"
  And I activate the "A multi-params app" node in the tree
  Then my active tab should be "A multi-params app"
  And the HTML tab should say "hello world"

Scenario: Appending parameters before running a command
  Given I will set "world" as a parameter
  When I open the runnables tree
  And I expand the tree row "fixture_runnables"
  And I append parameters to the "An appendable app" node in the tree
  Then my active tab should be "An appendable app"
  And the HTML tab should say "hello world"

Scenario: Appending parameters to a command which ends in parameters is disallowed
  Given I will set "runnable_app.rb" as a parameter
  And I will set "there" as a parameter
  When I open the runnables tree
  And I expand the tree row "fixture_runnables"
  And I append parameters to the "A params app" node in the tree
  Then my active tab should be "A params app"
  And the HTML tab should say "hello world"