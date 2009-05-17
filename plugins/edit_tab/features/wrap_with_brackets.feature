Feature: Type " or ( to wrap selection with parentheses

  Scenario: Type " to wrap selection
    Given there is an EditTab open
    When I type "Ah"
    And I press "Shift+Left" then "Shift+Left"
    And I press "\""
    Then I should see "\"Ah\"<c>" in the EditTab

  Scenario: Type ( to wrap selection
    Given there is an EditTab open
    When I type "Ah"
    And I press "Shift+Left" then "Shift+Left"
    And I press "("
    Then I should see "(Ah)<c>" in the EditTab

  Scenario: Type < should do nothing in Plain Text mode
    Given there is an EditTab open
    When I type "Ah"
    And I press "Shift+Left" then "Shift+Left"
    And I press "<"
    Then I should see "<<c>" in the EditTab

  Scenario: Type < should do everything in HTML mode
    Given there is an EditTab open with syntax "HTML"
    When I type "Ah"
    And I press "Shift+Left" then "Shift+Left"
    And I press "<"
    Then I should see "<Ah><c>" in the EditTab
