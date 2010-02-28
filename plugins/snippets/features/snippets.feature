Feature: Snippets

  Scenario: Simple content snippet
    Given there is a snippet with tab trigger "DBL" and scope "" and content
      """
        Daniel Benjamin Lucraft
      """
    When I open a new edit tab
    And I replace the contents with "DBL<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "Daniel Benjamin Lucraft<c>"
    
