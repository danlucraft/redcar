@project-fixtures
Feature: Refresh directory tree

  Scenario: Does not refresh instantly
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    Then I should see "lib,spec,README" in the tree
    And I should not see "testyfile.txt" in the tree
    When I touch the file "plugins/project/spec/fixtures/myproject/testyfile.txt"
    Then I should not see "testyfile.txt" in the tree

  Scenario: I can manually refresh the tree
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    Then I should see "lib,spec,README" in the tree
    And I should not see "testyfile.txt" in the tree
    When I touch the file "plugins/project/spec/fixtures/myproject/testyfile.txt"
    And I refresh the directory tree
    Then I should see "lib,spec,README,testyfile.txt" in the tree

  Scenario: Changing windows refreshed the tree
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    Then I should see "lib,spec,README" in the tree
    And I should not see "testyfile.txt" in the tree
    When I touch the file "plugins/project/spec/fixtures/myproject/testyfile.txt"
    When I open a new window
    And I focus the window "myproject" with a command
    Then I should see "lib,spec,README,testyfile.txt" in the tree
    
  Scenario: Refreshing the tree leaves rows expanded as they were before
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    And I expand the tree row "lib"
    Then I should see "lib,foo_lib.rb,vendor" in the tree
    And I refresh the directory tree
    Then I should see "lib,foo_lib.rb,vendor" in the tree
  
  Scenario: Tree is moved
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    When I open a directory
    And I move the myproject fixture away
    And I refresh the directory tree
    Then I should not see "lib" in the tree  
