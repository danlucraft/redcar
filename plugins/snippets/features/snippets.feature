Feature: Snippets

  Scenario: Simple content snippet in global scope
    Given there is a snippet with tab trigger "DBL" and scope "" and content
      """
        Daniel Benjamin Lucraft
      """
    When I open a new edit tab
    And I replace the contents with "DBL<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "Daniel Benjamin Lucraft<c>"

  Scenario: Simple content snippet in plain text scope
    Given there is a snippet with tab trigger "DBL" and scope "text.plain" and content
      """
        Daniel Benjamin Lucraft
      """
    When I open a new edit tab
    And I replace the contents with "DBL<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "Daniel Benjamin Lucraft<c>"

  Scenario: Inserts Textmate environment variable TM_LINE_INDEX
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix ${TM_LINE_INDEX} Gaeta
      """
    When I open a new edit tab
    And I replace the contents with "0123 fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "0123 Felix 5 Gaeta<c>"

  Scenario: Inserts Textmate environment variable TM_LINE_INDEX without curlies
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix $TM_LINE_INDEX Gaeta
      """
    When I open a new edit tab
    And I replace the contents with "0123 fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "0123 Felix 5 Gaeta<c>"


  Scenario: Transforms Textmate environment variables
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix ${TM_CURRENT_LINE/Co/ChiefOfStaff/} Gaeta
      """
    When I open a new edit tab
    And I replace the contents with "CoABC fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "CoABC Felix ChiefOfStaffABC  Gaeta<c>"


  #Scenario: Escapes dollars
  #  Given there is a snippet with tab trigger "DBL" and scope "text.plain" and content
  #    """
  #      Daniel \$1 Benjamin Lucraft
  #    """
  #  When I open a new edit tab
  #  And I replace the contents with "DBL<c>"
  #  And I press the Tab key in the edit tab
  #  Then the contents should be "Daniel $1 Benjamin Lucraft<c>"





