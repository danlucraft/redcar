Feature: Align Assignment

  Background:
    When I open a new edit tab

  Scenario: Upcase selected text
    When I replace the contents with "a = 4\nbc = 5"
    And I select from 0 to 12
    And I run the command Redcar::EditView::AlignAssignmentCommand
    Then the contents should be "<c>a  = 4\nbc = 5<s>"