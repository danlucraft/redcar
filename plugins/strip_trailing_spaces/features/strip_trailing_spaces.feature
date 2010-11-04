Feature: Strip Trailing Spaces
  As a user
  I sometimes want my editor to split trailing spaces on save

  Background:
    Given I will choose "plugins/strip_trailing_spaces/features/fixtures/test.txt" from the "open_file" dialog
    And I open a file
    And I replace the contents with "Hi \n \n Foo \n"

  Scenario: Strip spaces on save
    When I click "Enabled" from the "Plugins/Strip Trailing Spaces" menu
    When I click "Strip Blank Lines" from the "Plugins/Strip Trailing Spaces" menu
    And I save the tab
    Then I should see "Hi\n\n Foo\n" in the edit tab

  Scenario: Keep cursor position on save
    When I move the cursor to 8
    And I save the tab
    Then the contents should be "Hi\n\n F<c>oo\n"

  Scenario: Keep closest cursor position on save
    When I move the cursor to 5
    And I save the tab
    Then the contents should be "Hi\n<c>\n Foo\n"

  Scenario: Strip spaces, but not newlines on save
    When I click "Strip Blank Lines" from the "Plugins/Strip Trailing Spaces" menu
    And I save the tab
    Then I should see "Hi\n \n Foo\n" in the edit tab

  Scenario: Strip nothing on save
    When I click "Enabled" from the "Plugins/Strip Trailing Spaces" menu
    And I save the tab
    Then I should see "Hi \n \n Foo \n" in the edit tab
