@speedbar
Feature: Extended search

  Background:
    Given I open a new edit tab

  Scenario: Open extended search speedbar
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command DocumentSearch::ExtendedSearchCommand
    Then the DocumentSearch::ExtendedSearch::SearchSpeedbar speedbar should be open

  Scenario: Open extended search speedbar with initial selection
    When I replace the contents with "Foo\nBar\nBaz"
    And I select from 4 to 7
    And I run the command DocumentSearch::ExtendedSearchCommand
    Then the DocumentSearch::ExtendedSearch::SearchSpeedbar speedbar should be open
    And the "Search" field in the speedbar should have text "Bar"
    When I type "Foo" into the "Replace" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I check "Wrap Around" in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nFoo\nBaz"
    And the selected text should be ""
    And the selection range should be from 7 to 7

  Scenario: Find next with wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 0
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Foo" into the "Search" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I check "Wrap Around" in the speedbar
    And I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    
   Scenario: Find next without wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 0
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Foo" into the "Search" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I uncheck "Wrap Around" in the speedbar
    And I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be ""
    And the selection range should be from 11 to 11

  Scenario: Find previous with wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 18
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Foo" into the "Search" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I check "Wrap Around" in the speedbar
    And I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11

  Scenario: Find previous without wrap around
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 18
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Foo" into the "Search" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I uncheck "Wrap Around" in the speedbar
    And I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    When I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I press "Previous" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be ""
    And the selection range should be from 0 to 0

  Scenario: Find with regular expression
    When I replace the contents with "Foo\nBar Foo\nHmm\nBaz"
    And I move the cursor to 0
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Fo." into the "Search" field in the speedbar
    And I choose "Regex" in the "search_type" field in the speedbar
    And I check "Wrap Around" in the speedbar
    And I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 0 to 3
    When I press "Next" in the speedbar
    Then the contents should be "Foo\nBar Foo\nHmm\nBaz"
    And the selected text should be "Foo"
    And the selection range should be from 8 to 11
    
  Scenario: Replace and find with no initial selection
    When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And I move the cursor to 0
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Rab" into the "Search" field in the speedbar
    And I type "RABBIT" into the "Replace" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I check "Wrap Around" in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 19 to 22
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 30 to 33
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 22 to 25

  Scenario: Replace and find with matching initial selection
    When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And I select from 12 to 15
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Rab" into the "Search" field in the speedbar
    And I type "RABBIT" into the "Replace" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I check "Wrap Around" in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 19 to 22
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 30 to 33
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 22 to 25

  Scenario: Replace and find with initial selection that doesn't match
    When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And I select from 4 to 7
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Rab" into the "Search" field in the speedbar
    And I type "RABBIT" into the "Replace" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I check "Wrap Around" in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 19 to 22
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 30 to 33
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 22 to 25

  Scenario: Replace and find with initial selection that is after last match
    When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And I select from 28 to 31
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Rab" into the "Search" field in the speedbar
    And I type "RABBIT" into the "Replace" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I check "Wrap Around" in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 19 to 22
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRab\nFoo\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 30 to 33
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 12 to 15
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo RABBITBIT RABBIT\nHmm\nRABBIT\nFoo\nBaz"
    And the selected text should be "RAB"
    And the selection range should be from 22 to 25

  Scenario: Replace and find with initial selection that is after last match and no wrap around
    When I replace the contents with "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And I select from 28 to 31
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Rab" into the "Search" field in the speedbar
    And I type "RABBIT" into the "Replace" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I uncheck "Wrap Around" in the speedbar
    And I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be ""
    And the selection range should be from 31 to 31
    When I press "Replace && Find" in the speedbar
    Then the contents should be "Foo\nBar Foo Rab Rab\nHmm\nRab\nFoo\nBaz"
    And the selected text should be ""
    And the selection range should be from 31 to 31

  Scenario: Replace all replaces one
    When I replace the contents with "Foo\nBar\nBaz"
    And I move the cursor to 0
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Bar" into the "Search" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I uncheck "Wrap Around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "Foo\nRab\nBaz"
    And the selected text should be "Rab"
    And the selection range should be from 4 to 7
  
  Scenario: Replace all replaces two
    When I replace the contents with "Foo\nBar\nBaz\nBar\nQux"
    And I move the cursor to 0
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "Bar" into the "Search" field in the speedbar
    And I type "Rab" into the "Replace" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I uncheck "Wrap Around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "Foo\nRab\nBaz\nRab\nQux"
    And the selected text should be "Rab"
    And the selection range should be from 12 to 15
   
  Scenario: Replace all replaces two on the same line
    When I replace the contents with "abcabc"
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "bc" into the "Search" field in the speedbar
    And I type "xx" into the "Replace" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I uncheck "Wrap Around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "axxaxx"
    And the selected text should be "xx"
    And the selection range should be from 4 to 6
    When I press "Replace All" in the speedbar
    Then the contents should be "axxaxx"
    And the selected text should be "xx"
    And the selection range should be from 4 to 6
  
  Scenario: Replace all replaces overlapping occurences on the same line
    When I replace the contents with "deedeedeed"
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "deed" into the "Search" field in the speedbar
    And I type "misdeed" into the "Replace" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I uncheck "Wrap Around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "misdeedeemisdeed"
    And the selected text should be "misdeed"
    And the selection range should be from 9 to 16
  
  Scenario: Replace all is a single undo action
    When I replace the contents with "Foo\n\nabcabc\n\nBar"
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "bc" into the "Search" field in the speedbar
    And I type "xx" into the "Replace" field in the speedbar
    And I choose "Plain" in the "search_type" field in the speedbar
    And I uncheck "Wrap Around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "Foo\n\naxxaxx\n\nBar"
    And the selected text should be "xx"
    And the selection range should be from 9 to 11
    When I undo
    Then the contents should be "Foo\n\nabcabc\n\nBar"

  Scenario: Replace all regex with back-references
    When I replace the contents with "One fish\ntwo fish\nred fish\nblue fish"
    And I move the cursor to 0
    And I run the command DocumentSearch::ExtendedSearchCommand
    And I type "(\w+) fish" into the "Search" field in the speedbar
    And I type "\1 car" into the "Replace" field in the speedbar
    And I choose "Regex" in the "search_type" field in the speedbar
    And I uncheck "Wrap Around" in the speedbar
    And I press "Replace All" in the speedbar
    Then the contents should be "One car\ntwo car\nred car\nblue car"
    And the selected text should be "blue car"
    And the selection range should be from 24 to 32
    
  # TODO: Scenarios with match case
  # TODO: Scenarios with glob search type
