Feature: Align Assignment

  Background:
    When I open a new edit tab

  Scenario: align simple assignments
    When I replace the contents with "a = 4\nbc = 5\nd = 123"
    And I select all
    And I run the command Redcar::EditView::AlignAssignmentCommand
    Then the contents should be "<c>a  = 4\nbc = 5\nd  = 123<s>"

  Scenario: align rows that have empty lines
    When I replace the contents with "a = 1\n\nab = 123"
    And I select all
    And I run the command Redcar::EditView::AlignAssignmentCommand
    Then the contents should be "<c>a  = 1\n\nab = 123<s>"

  Scenario: preserve trailing newline
    Given the content is:
        """
        def foo
        <c>  a = 1
          bb = 2
          ccc = 3
        <s>end
        """
    When I run the command Redcar::EditView::AlignAssignmentCommand
    Then the content should be:
        """
        def foo
        <c>  a   = 1
          bb  = 2
          ccc = 3<s>
        end
        """

  Scenario: preserve non-selected indentation
    Given the content is:
        """
        def foo
          <c>a = 1
          bb = 2
          ccc = 3<s>
        end
        """
    When I run the command Redcar::EditView::AlignAssignmentCommand
    Then the content should be:
        """
        def foo
        <c>  a   = 1
          bb  = 2
          ccc = 3<s>
        end
        """

#  Scenario: align the right hand side of the operator
#    Given the content is:
#        """
#        def foo
#        <c>  a = 1
#          bb =     2
#          ccc = 3<s>
#        end
#        """
#    When I run the command Redcar::EditView::AlignAssignmentCommand
#    Then the content should be:
#        """
#        def foo
#        <c>  a   = 1
#          bb  = 2
#          ccc = 3<s>
#        end
#        """