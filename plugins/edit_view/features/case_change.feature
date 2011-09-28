Feature: Change Case

  Background:
    When I open a new edit tab

  Scenario: Upcase selected text
    When I replace the contents with "Curry Chicken"
    And I select -5 from (0,5)
    And I select menu item "Edit|Formatting|Convert Text|to Uppercase"
    Then the contents should be "<c>CURRY<s> Chicken"

  Scenario: Upcase selected text and preserve cursor position
    When I replace the contents with "Curry Chicken"
    And I select 5 from (0,0)
    And I select menu item "Edit|Formatting|Convert Text|to Uppercase"
    Then the contents should be "<s>CURRY<c> Chicken"

  Scenario: Upcase word if no selection
    When I replace the contents with "Curry Chicken"
    And I move the cursor to (0,10)
    And I select menu item "Edit|Formatting|Convert Text|to Uppercase"
    Then the contents should be "Curry CHIC<c>KEN"

  Scenario: Downcase text
    When I replace the contents with "CURRY CHICKEN"
    And I select 5 from (0,0)
    And I select menu item "Edit|Formatting|Convert Text|to Lowercase"
    Then the contents should be "<s>curry<c> CHICKEN"

  Scenario: Titlize text
    When I replace the contents with "curry chicken"
    And I select 13 from (0,0)
    And I select menu item "Edit|Formatting|Convert Text|to Titlecase"
    Then the contents should be "<s>Curry Chicken<c>"
    When I replace the contents with "CURRY CHICKEN"
    And I select 13 from (0,0)
    And I select menu item "Edit|Formatting|Convert Text|to Titlecase"
    Then the contents should be "<s>Curry Chicken<c>"

  Scenario: Opposite case
    When I replace the contents with "Curry Chicken"
    And I select 13 from (0,0)
    And I select menu item "Edit|Formatting|Convert Text|to Opposite Case"
    Then the contents should be "<s>cURRY cHICKEN<c>"

  Scenario: Camel case
    When I replace the contents with "curry_chicken"
    And I move the cursor to (0,13)
    And I select menu item "Edit|Formatting|Convert Text|to CamelCase"
    Then the contents should be "CurryChicken<c>"

  Scenario: Underscore
    When I replace the contents with "CurryChicken"
    And I move the cursor to (0,12)
    And I select menu item "Edit|Formatting|Convert Text|to snake_case"
    Then the contents should be "curry_chicke<c>n"

  Scenario: Pascal to Underscore to Camel Case rotation
    When I replace the contents with "CurryChicken"
    And I move the cursor to (0,12)
    And I select menu item "Edit|Formatting|Convert Text|Toggle PascalCase-underscore-camelCase"
    Then the contents should be "curry_chicke<c>n"
    And I select menu item "Edit|Formatting|Convert Text|Toggle PascalCase-underscore-camelCase"
    Then the contents should be "curryChicken<c>"
    And I select menu item "Edit|Formatting|Convert Text|Toggle PascalCase-underscore-camelCase"
    Then the contents should be "CurryChicken<c>"

