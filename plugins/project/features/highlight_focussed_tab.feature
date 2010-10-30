Feature: Highlight the File of the focussed tab in tree

  Scenario: Opening a file should reveal it in the tree
    Given I will choose "." from the "open_directory" dialog
    And I open a directory
    And I have opened "plugins/project/features/highlight_focussed_tab.feature"
    Then there should be one edit tab
    And "highlight_focussed_tab.feature" should be selected in the project tree

  Scenario: Switching between tabs should highlight them in the tree
    Given I will choose "." from the "open_directory" dialog
    And I open a directory
    And I have opened "plugins/project/features/highlight_focussed_tab.feature"
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
    Given I will choose "." from the "open_directory" dialog
    And I open a directory
    And I have opened "plugins/project/features/highlight_focussed_tab.feature"
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