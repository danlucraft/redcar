Feature: Snippets
  As a user
  I want to speed myself up with snippets

  Scenario: Inserts snippet contents
    Given there is an EditTab open with syntax "Ruby"
    When I type "def"
    And I press "Tab"
    Then I should see "def <s>method_name<c>\n\t\nend" in the EditTab

  Scenario: Presents options when multiple
    Given there is an EditTab open with syntax "Ruby"
    When I type "cla"
    And I press "Tab"
    Then I should see a menu with "class .. end"

  Scenario: Inserts snippet from menu
    Given there is an EditTab open with syntax "Ruby"
    When I type "cla"
    And I press "Tab" then "1"
    Then I should see "class" in the EditTab

  Scenario: Inserts tab if no snippets
    Given there is an EditTab open with syntax "Ruby"
    When I type "asdf"
    And I press "Tab" then "x"
    Then I should see "asdf  x" in the EditTab

  Scenario: Sets correct environment variables based on scope
    Given there is an EditTab open with syntax "Ruby"
    When I press "Ctrl+Shift+B"
    Then I should see "# ==========\n# = <s>Banner<c> =\n# ==========" in the EditTab

  Scenario: Comment snippet is inserted correct
    Given there is an EditTab open with syntax "Ruby"
    When I type "foo\nbar\nbaz"
    And I press "Up"
    When I press "Super+/"
    Then I should see "foo\n# bar<c>\nbaz" in the EditTab
