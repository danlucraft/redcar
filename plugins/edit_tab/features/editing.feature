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
    Then I should see "xx<c>" in the EditTab
    And I should not see "aa" in the EditTab

  Scenario: Convert selected text to uppercase
    When I type "Some Text"
    And I press "Ctrl+Shift+L"
    And I press "Ctrl+U"
    Then I should see "SOME TEXT" in the EditTab

  Scenario: Convert current word to uppercase
    When I type "Some Text"
    And I press "Ctrl+A"
    And I press "Ctrl+U"
    Then I should see "<c>SOME Text" in the EditTab

  Scenario: Convert selected text to lowercase
    When I type "Some Text"
    And I press "Ctrl+Shift+L" 
    And I press "Ctrl+Shift+U"
    Then I should see "some text" in the EditTab

  Scenario: Convert current word to lowercase
    When I type "Some Text"
    And I press "Ctrl+E"
    And I press "Ctrl+Shift+U"
    Then I should see "Some text<c>" in the EditTab

  Scenario: Convert selected uppercase text to titlecase
    When I type "SOME TEXT"
    And I press "Ctrl+Shift+L" 
    And I press "Ctrl+Alt+U"
    Then I should see "Some Text" in the EditTab

  Scenario: Convert selected lowercase text to titlecase
    When I type "some text"
    And I press "Ctrl+Shift+L" 
    And I press "Ctrl+Alt+U"
    Then I should see "Some Text" in the EditTab

  Scenario: Convert current line to titlecase
    When I type "some text"
    And I press "Ctrl+Alt+U"
    Then I should see "Some Text" in the EditTab

  Scenario: Paste history
    When I type "ab"
    And I press "Ctrl+Shift+L" then "Ctrl+C"
    And I press "Ctrl+E" then "Ctrl+V"
    And I press "Ctrl+Alt+V" then "Down"
    And I press "Return"
    Then I should see "ababab<c>" in the EditTab

  Scenario: Paste cycle
    When I type "a"
    And I press "Ctrl+Shift+L" then "Ctrl+C"
    And I press "Ctrl+E" then "Ctrl+V"
    And I press "Return" then "b"
    And I press "Ctrl+Shift+L" then "Ctrl+C"
    And I press "Ctrl+E" then "Ctrl+V"
    And I press "Return" then "c"
    And I press "Ctrl+Shift+L" then "Ctrl+C"
    And I press "Ctrl+E" then "Ctrl+V"
    And I press "Return" then "Ctrl+Alt+B"
    And I press "Ctrl+Super+V" then "Ctrl+Super+V"
    Then I should see "b" in the EditTab 

  Scenario: Select word
    When I type "foo bar"
    And I press "Left" then "Super+W"
    Then I should see "foo <s>bar<c>" in the EditTab

  Scenario: Select word at end of word
    When I type "foo bar"
    And I press "Super+W"
    Then I should see "foo <s>bar<c>" in the EditTab

  Scenario: Select word does nothing outside of word
    When I type "foo bar "
    And I press "Super+W"
    Then I should see "foo bar <c>" in the EditTab




