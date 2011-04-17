@runnables
Feature: Running commands in a tab
  # 
  # Background:
  #   When I will choose "plugins/runnables/features/fixtures" from the "open_directory" dialog
  #   And I open a directory
  # 
  # Scenario: Running a command from the tree
  #   When I open the runnables tree
  #   And I expand the tree row "fixture_runnables"
  #   And I activate the "An app" node in the tree
  #   Then my active tab should be "An app"
  #   And the HTML tab should say "hello world"
  #   
  # Scenario: Running a command based on a file name
  #   Given I have opened "plugins/runnables/features/fixtures/runnable_app.rb"
  #   And I run the command Redcar::Runnables::RunEditTabCommand
  #   Then my active tab should be "Running runnable_app.rb"
  #   And the HTML tab should say "hello world"
  # 
  # Scenario: Running a command without output
  #   Given I have opened "plugins/runnables/features/fixtures/runnable_app.rb"
  #   And I open the runnables tree
  #   And I expand the tree row "fixture_runnables"
  #   And I activate the "A silent app" node in the tree
  #   Then my active tab should be "runnable_app.rb"
  # 
  # Scenario: Running a command with windowed output
  #   Given I open the runnables tree
  #   And I expand the tree row "fixture_runnables"
  #   And I note the number of windows
  #   And I activate the "A windowed app" node in the tree
  #   Then I should see 1 more window
  #   And the HTML tab should say "hello world"
  # 
  # Scenario: Re-running a command with windowed output
  #   Given I open the runnables tree
  #   And I expand the tree row "fixture_runnables"
  #   And I note the number of windows
  #   And I activate the "A windowed app" node in the tree
  #   And the HTML tab says "hello world"
  #   And I go back to the "fixtures" window
  #   And I activate the "A windowed app" node in the tree
  #   Then I should see 1 more window
  #   And the HTML tab should say "hello world"
  #   
  # 