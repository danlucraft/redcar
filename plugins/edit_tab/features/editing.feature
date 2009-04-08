Feature: Edit Text
  As a user
  I want to be able to edit the text in my tabs

  Background:
    Given there is an EditTab open

  Scenario: Type some text
    When I type "def foo"
    Then I should see "def foo<c>" in the EditTab
  
  Scenario: Move cursor left
    When I type "def foo"
    And I press "Left"
    Then I should see "def fo<c>o" in the EditTab
  
  Scenario: Up
    When I type "def foo\n  p :foo\nend"
    And I press "Up"
    Then I should see "p<c> :foo" in the EditTab
  
  Scenario: Page up
    When I type "def foo"
    And I press "Page_Up"
    Then I should see "<c>def foo" in the EditTab
  
  Scenario: Move to line start
    When I type "def foo"
    And I press "Ctrl+A"
    Then I should see "<c>def foo" in the EditTab
  
  Scenario: Move to line end
    When I type "def foo"
    And I press "Left" then "Left"
    And I press "Ctrl+E"
    Then I should see "def foo<c>" in the EditTab
  
  Scenario: Kill line
    When I type "def foo"  
    And I press "Left" then "Left"
    And I press "Ctrl+K"
    Then I should see "def f<c>" in the EditTab
    And I should not see "oo" in the EditTab

  Scenario: Paste 
    When I type "aaxx"
    And I press "Shift+Left" then "Shift+Left"
    And I press "Ctrl+X"
    And I press "Left" then "Left"
    And I press "Ctrl+V"
    Then I should see "xx<c>aa" in the EditTab

  Scenario: Paste over a selection
    When I type "aaxx"
    And I press "Shift+Left" then "Shift+Left"
    And I press "Ctrl+X"
    And I press "Shift+Left" then "Shift+Left"
    And I press "Ctrl+V"
    Then I should see "<s>xx<c>" in the EditTab
    And I should not see "aa" in the EditTab
