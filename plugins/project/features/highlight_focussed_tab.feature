Feature: Highlight the File of the focussed tab in tree

  Background:
    Given I will choose "." from the "open_directory" dialog
    And I open a directory
    And I have opened "plugins/project/features/highlight_focussed_tab.feature"

  Scenario: Opening a file should reveal it in the tree
    Then there should be one edit tab
    Then "highlight_focussed_tab.feature" should be selected in the project tree

  Scenario: Switching between tabs should highlight them in the tree
    Then "highlight_focussed_tab.feature" should be selected in the project tree
    And I have opened "plugins/project/features/find_file.feature"
    And I have opened "plugins/project/features/move_and_rename_files.feature"
    Then there should be 3 edit tabs
    And "move_and_rename_files.feature" should be selected in the project tree
    And I switch up a tab
    Then "find_file.feature" should be selected in the project tree
    And I switch up a tab
    Then "highlight_focussed_tab.feature" should be selected in the project tree

  Scenario: Project revelation should work across several notebooks
    And I have opened "plugins/project/features/find_file.feature"
    And I have opened "plugins/project/features/move_and_rename_files.feature"
    And I have opened "plugins/project/features/sub_project.feature"
    And I make a new notebook
    And I move the tab to the other notebook
    And I move the tab to the other notebook
    And I switch notebooks
    Then "sub_project.feature" should be selected in the project tree
    And I switch up a tab
    Then "move_and_rename_files.feature" should be selected in the project tree
    And I switch notebooks
    Then "find_file.feature" should be selected in the project tree

  Scenario: Project revelation doesn't get triggered on REPLs
    Then there should be one edit tab
    Then "highlight_focussed_tab.feature" should be selected in the project tree
    And I open a "ruby" repl
    Then "highlight_focussed_tab.feature" should be selected in the project tree
    And I open a "clojure" repl
    Then "highlight_focussed_tab.feature" should be selected in the project tree
    And I open a "groovy" repl
    Then "highlight_focussed_tab.feature" should be selected in the project tree

  Scenario Outline: Highlight focussed tab only works when enabled and project tree is visible
    When I <disable highlighting>
    When I have opened "plugins/project/features/find_file.feature"
    Then "highlight_focussed_tab.feature" should be selected in the project tree
    When I have opened "plugins/project/features/sub_project.feature"
    Then "highlight_focussed_tab.feature" should be selected in the project tree

    Examples:
      | disable highlighting                     |
      | toggle tree visibility                   |
      | click Show Bundles in Tree               |
      | prefer to not highlight the focussed tab |