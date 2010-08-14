Feature: Showing commands in a command tree

  Background:
    When I will choose "plugins/runnables/features/fixtures" from the "open_directory" dialog
    And I open a directory

  Scenario: Shows grouped commands from .redcar/runnables/*.json in the project
    When I open the runnables tree
    Then I should see "fixture_runnables" in the tree
  
  Scenario: Shows individual commands in groups
    When I open the runnables tree
    And I expand the tree row "fixture_runnables"
    Then I should see "An app" in the tree

  Scenario: I can manually refresh the tree
    When I open the runnables tree
    And I change the command to "A changed app"
    And I open the runnables tree
    And I expand the tree row "fixture_runnables"
    Then I should see "A changed app" in the tree
    
  #  
  #Scenario: Changing windows refreshed the tree
  #  Given I will choose "." from the "open_directory" dialog
  #  When I open a directory
  #  Then I should see "bin,config,lib,plugins" in the tree
  #  And I should not see "testyfile.txt" in the tree
  #  When I touch the file "./testyfile.txt"
  #  When I open a new window
  #  And I focus the working directory window through the gui
  #  Then I should see "bin,config,lib,plugins,testyfile.txt" in the tree
  #  
  #Scenario: Refreshing the tree leaves rows expanded as they were before
  #  Given I will choose "." from the "open_directory" dialog
  #  When I open a directory
  #  And I expand the tree row "lib"
  #  Then I should see "bin,config,lib,freebase2,plugins" in the tree
  #  And I refresh the directory tree
  #  Then I should see "bin,config,lib,freebase2,plugins" in the tree
  #
  #Scenario: Tree is moved
  #  Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
  #  When I open a directory
  #  And I move the myproject fixture away
  #  And I refresh the directory tree
  #  Then I should not see "lib" in the tree  
