Feature: Fuzzy file finder
  I want to be able to jump quickly to files in my project

  Background:
    Given the ProjectTab is open
    When I add the directory "plugins/project" to the ProjectTab

  Scenario: Jump to exactly named file
    When I press "Super+T"
    And I type "fuzzy_file_finder.feature"
    And I press "Return"
    Then there should be one EditTab open
    And the label of the EditTab should say "fuzzy_file_finder.feature"

  Scenario: Jump to partially named file
    When I press "Super+T"
    And I type "fufifife"
    And I press "Return"
    Then there should be one EditTab open
    And the label of the EditTab should say "fuzzy_file_finder.feature"

  Scenario: First matching file should be shorter
    When I press "Super+T"
    And I type "newinprojcommand"
    And I press "Return"
    Then there should be one EditTab open
    And the label of the EditTab should say "new_file_in_project_command.rb"

  Scenario: Jump to second of several matching files
    When I press "Super+T"
    And I type "newinprojcommand"
    And I press "Down"
    And I press "Return"
    Then there should be one EditTab open
    And the label of the EditTab should say "new_directory_in_project_command.rb"
