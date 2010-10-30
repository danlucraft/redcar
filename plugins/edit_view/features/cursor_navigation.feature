Feature: Cursor navigation

  Background:
    When I open a new edit tab

  Scenario: Move forward word works with multi-byte chars
    When I replace the contents with "<h1>'Oáy z' wee"
    And I move the cursor to 0
    When I move to the next word
    Then the contents should be "<h1<c>>'Oáy z' wee"
    When I move to the next word
    Then the contents should be "<h1>'<c>Oáy z' wee"
    When I move to the next word
    Then the contents should be "<h1>'Oáy<c> z' wee"
    When I move to the next word
    Then the contents should be "<h1>'Oáy z<c>' wee"
    When I move to the next word
    Then the contents should be "<h1>'Oáy z' <c>wee"
    When I move to the next word
    Then the contents should be "<h1>'Oáy z' wee<c>"

  Scenario: Move backward word works with multi-byte chars
    When I replace the contents with "<h1>'Oáy z' wee"
    And I move the cursor to 15
    When I move to the previous word
    Then the contents should be "<h1>'Oáy z' <c>wee"
    When I move to the previous word
    Then the contents should be "<h1>'Oáy z<c>' wee"
    When I move to the previous word
    Then the contents should be "<h1>'Oáy <c>z' wee"
    When I move to the previous word
    Then the contents should be "<h1>'<c>Oáy z' wee"
    When I move to the previous word
    Then the contents should be "<h1<c>>'Oáy z' wee"
    When I move to the previous word
    Then the contents should be "<<c>h1>'Oáy z' wee"
