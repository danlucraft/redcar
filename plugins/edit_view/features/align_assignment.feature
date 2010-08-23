Feature: Align Assignment

  Background:
    When I open a new edit tab

  Scenario: align simple assignments
    When I replace the contents with "a = 4\nbc = 5\nd = 123"
    And I select all
    And I run the command Redcar::EditView::AlignAssignmentCommand
    Then the contents should be "<c>a  = 4\nbc = 5\nd  = 123<s>"