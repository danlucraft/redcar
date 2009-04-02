Feature: Snippets
  As a user
  I want to speed myself up with snippets

  Background:
    Given there is an EditTab open with syntax "Ruby"

  Scenario: Inserts snippet contents
    When I type "def"
    And I press "Tab"
    Then I should see "def <s>method_name<c>\n\t\nend" in the EditTab

  Scenario: Presents options when multiple
    When I type "cla"
    And I press "Tab"
    Then I should see a menu with "class .. end"

  Scenario: Inserts snippet from menu
    When I type "cla"
    And I press "Tab" then "1"
    Then I should see "class" in the EditTab

  Scenario: Inserts tab if no snippets
    When I type "asdf"
    And I press "Tab" then "x"
    Then I should see "asdf  x" in the EditTab

  Scenario: Sets correct environment variables based on scope
    When I press "Ctrl+Shift+B"
    Then I should see "# ==========\n# = <s>Banner<c> =\n# ==========" in the EditTab
