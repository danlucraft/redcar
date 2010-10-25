Feature: Highlight the File of the focussed tab in tree

  Scenario: Opening a file should reveal it in the tree
    Given I will choose "." from the "open_directory" dialog
    And I open a directory
    And I have opened "plugins/project/features/highlight_focussed_tab.feature"
    Then there should be one edit tab
    And "highlight_focussed_tab.feature" should be selected in the project tree
