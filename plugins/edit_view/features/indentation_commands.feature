Feature: Indentation commands

  Scenario: Increase indent, soft tabs, width 2
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I select menu item "Edit|Formatting|Increase Indent"
    Then the contents should be "  "

  Scenario: Decrease indent, soft tabs, width 2
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I replace the contents with "<c>    "
    And I select menu item "Edit|Formatting|Decrease Indent"
    Then the contents should be "  "

  Scenario: Increase indent, soft tabs, width 3
    When I open a new edit tab
    And tabs are soft, 3 spaces
    And I select menu item "Edit|Formatting|Increase Indent"
    Then the contents should be "   "

  Scenario: Decrease indent, soft tabs, width 3
    When I open a new edit tab
    And tabs are soft, 3 spaces
    And I replace the contents with "<c>      "
    And I select menu item "Edit|Formatting|Decrease Indent"
    Then the contents should be "   "

  Scenario: Increase indent, hard tabs, width 2
    When I open a new edit tab
    And tabs are hard
    And I select menu item "Edit|Formatting|Increase Indent"
    Then the contents should be "\t"

  Scenario: Decrease indent, hard tabs, width 2
    When I open a new edit tab
    And tabs are hard
    And I replace the contents with "<c>\t\t"
    And I select menu item "Edit|Formatting|Decrease Indent"
    Then the contents should be "\t"

  Scenario: auto-indent, soft tabs, width 2
    Given the indentation rules are like Ruby's
    When I open a new edit tab
    And tabs are soft, 2 spaces
    And I replace the contents with "def f\n\t1\t\t\nend\t"
    And I select 13 from (0,0)
    And I select menu item "Edit|Formatting|Indent"
    Then the contents should be "def f\n  1\nend"