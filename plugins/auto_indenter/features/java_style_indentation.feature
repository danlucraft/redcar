Feature: Indents Java code correctly

  Background:
    Given the indentation rules are like Java's
    When I open a new edit tab
    And tabs are soft, 2 spaces
    
  Scenario: It should indent else blocks correctly
    Given the content is:
				"""
				  if(condition) {
				    // stuff goes here...
				  } 
				"""
    And I move the cursor to (2,4)
    When I type "e"
    Then the content should be:
				"""
				  if(condition) {
				    // stuff goes here...
				  } e<c>
				"""

  Scenario: It should expand blocks
    Given the content is:
				"""
				  if(condition) {}
				"""
    And I move the cursor to (0,17)
    When I type "\n"
    Then the content should be:
				"""
				  if(condition) {
				    <c>
				  }
				"""


