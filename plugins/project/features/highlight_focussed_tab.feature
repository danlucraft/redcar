@project-fixtures
Feature: Highlight the File of the focussed tab in tree

  Background:
    Given I will choose "plugins/project/spec/fixtures/myproject" from the "open_directory" dialog
    And I open a directory
    And I have opened "README" from the project

  Scenario: Opening a file should reveal it in the tree
    Then there should be one edit tab
    Then "README" should be selected in the project tree

  Scenario: Switching between tabs should highlight them in the tree
    Then "README" should be selected in the project tree
    And I have opened "lib/foo_lib.rb" from the project
    And I have opened "spec/foo_spec.rb" from the project
    Then there should be 3 edit tabs
    And "foo_spec.rb" should be selected in the project tree
    And I switch up a tab
    Then "foo_lib.rb" should be selected in the project tree
    And I switch up a tab
    Then "README" should be selected in the project tree

  Scenario: Project revelation should work across several notebooks
    And I have opened "lib/foo_lib.rb" from the project
    And I have opened "spec/foo_spec.rb" from the project
    And I have opened "vendor/bar.rb"
    And I make a new notebook
    And I move the tab to the other notebook
    And I move the tab to the other notebook
    And I switch notebooks
    Then "vendor/bar.rb" should be selected in the project tree
    And I switch up a tab
    Then "spec/foo_spec.rb" should be selected in the project tree
    And I switch notebooks
    Then "lib/foo_lib.rb" should be selected in the project tree

  Scenario: Project revelation doesn't get triggered on REPLs
    Then there should be one edit tab
    Then "README" should be selected in the project tree
    And I open a "ruby" repl
    Then "README" should be selected in the project tree

  Scenario Outline: Highlight focussed tab only works when enabled and project tree is visible
    When I <disable highlighting>
    When I have opened "lib/foo_lib.rb" from the project
    Then "README" should be selected in the project tree

    Examples:
      | disable highlighting                     |
      | toggle tree visibility                   |
      | click Show Bundles in Tree               |
      | prefer to not highlight the focussed tab |