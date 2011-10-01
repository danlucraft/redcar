Feature: Align Assignment

  Background:
    When I open a new edit tab

  Scenario: align simple assignments
    When I type "a = 4\nbc = 5\nd = 123"
    And I select all
    And I select menu item "Edit|Formatting|Align Assignments"
    Then the contents should be "<c>a  = 4\nbc = 5\nd  = 123<s>"

  Scenario: Operates on entire lines, not portions of lines
    Given the content is:
        """
        def foo
          a = 1
          bb = 2
          ccc = 3
        end
        """
    And I select from (1,2) to (3,9)
    And I select menu item "Edit|Formatting|Align Assignments"
    Then the content should be:
        """
        def foo
        <c>  a   = 1
          bb  = 2
          ccc = 3<s>
        end
        """
