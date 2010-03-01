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

  Scenario: Transforms Textmate environment variables global find and replace
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix ${TM_CURRENT_LINE/\w/CS /g} Gaeta
      """
    When I open a new edit tab
    And I replace the contents with "ABC fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "ABC Felix CS CS CS   Gaeta<c>"

  Scenario: Transforms Textmate environment variables escapes characters
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix ${TM_CURRENT_LINE/\w/C\/S /g} Gaeta
      """
    When I open a new edit tab
    And I replace the contents with "ABC fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "ABC Felix C/S C/S C/S   Gaeta<c>"

  Scenario: Inserts one tab stop
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t\nend
      """
    When I open a new edit tab
    And I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "if <c>\n\t\nend"

  Scenario: Selects tab stop zero
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if ${0:instance}
      """
    When I open a new edit tab
    And I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "if <s>instance<c>"

  Scenario: Allows tabbing past snippet
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t\nend
      """
    When I open a new edit tab
    And I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    And I press the Tab key in the edit tab
    Then the contents should be "if \n\t\nend<c>"

  Scenario: Allows tabbing between tab stops
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t$2\nend
      """
    When I open a new edit tab
    And I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    And I press the Tab key in the edit tab
    Then the contents should be "if \n\t<c>\nend"
    When I press the Tab key in the edit tab
    Then the contents should be "if \n\t\nend<c>"

  Scenario: Allows tabbing between nonconsecutive tab stops
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t$3\nend
      """
    When I open a new edit tab
    And I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    And I press the Tab key in the edit tab
    Then the contents should be "if \n\t<c>\nend"
    When I press the Tab key in the edit tab
    Then the contents should be "if \n\t\nend<c>"

  Scenario: Allows typing and tabbing
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t$2\nend
      """
    When I open a new edit tab
    And I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    And I insert "Pegasus" at the cursor
    And I press the Tab key in the edit tab
    Then the contents should be "if Pegasus\n\t<c>\nend"
    When I insert "Cain" at the cursor
    And I press the Tab key in the edit tab
    Then the contents should be "if Pegasus\n\tCain\nend<c>"

  Scenario: Allows shift tabbing
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t$2\nend
      """
    When I open a new edit tab
    And I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    And I insert "Pegasus" at the cursor
    And I press the Tab key in the edit tab
    Then the contents should be "if Pegasus\n\t<c>\nend"
    When I insert "Cain" at the cursor
    And I press Shift+Tab in the edit tab
    Then the contents should be "if <s>Pegasus<c>\n\tCain\nend"

  #Scenario: Escapes dollars
  #  Given there is a snippet with tab trigger "DBL" and scope "text.plain" and content
  #    """
  #      Daniel \$1 Benjamin Lucraft
  #    """
  #  When I open a new edit tab
  #  And I replace the contents with "DBL<c>"
  #  And I press the Tab key in the edit tab
  #  Then the contents should be "Daniel $1 Benjamin Lucraft<c>"





