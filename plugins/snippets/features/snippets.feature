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
    
  Scenario: Escapes dollars
    Given there is a snippet with tab trigger "DBL" and scope "text.plain" and content
      """
        Daniel \$1 Benjamin Lucraft
      """
    When I open a new edit tab
    And I replace the contents with "DBL<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "Daniel $1 Benjamin Lucraft<c>"

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

  Scenario: Inserts tab stop content
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if ${1:condition}\n\t$0\nend
      """
    When I open a new edit tab
    And I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "if <s>condition<c>\n\t\nend"

  Scenario: Inserts environment variable as placeholder
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix ${1:$TM_LINE_INDEX} Gaeta
      """
    When I open a new edit tab
    And I replace the contents with "ABC fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "ABC Felix 4 Gaeta"

  Scenario: Leaves snippet on cursor move
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if ${1:condition}\n\t$0\nend
      """
    When I open a new edit tab
    And tabs are hard
    And I replace the contents with "ABC if<c>"
    And I press the Tab key in the edit tab
    And I move the cursor to 0
    And I press the Tab key in the edit tab
    Then the contents should be "\t<c>ABC if condition\n\t\nend"

  Scenario: Multiple tab stops with content
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if ${1:condition}\n\t${2:code}\nend
      """
    When I open a new edit tab
    And I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "if <s>condition<c>\n\tcode\nend"
    And I press the Tab key in the edit tab
    Then the contents should be "if condition\n\t<s>code<c>\nend"
    And I press the Tab key in the edit tab
    Then the contents should be "if condition\n\tcode\nend<c>"

  Scenario: Mirrors mirror text
    Given there is a snippet with tab trigger "name2" and scope "text.plain" and content
      """
        name: $1\nname: $1
      """
    When I open a new edit tab
    And I replace the contents with "name2<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "name: <c>\nname: "
    And I insert "raider" at the cursor
    Then the contents should be "name: <c>raider\nname: raider"

  Scenario: Mirrors mirror tab stop with content
    Given there is a snippet with tab trigger "name2" and scope "text.plain" and content
      """
        name: ${1:leoban}\nname: $1
      """
    When I open a new edit tab
    And I replace the contents with "name2<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "name: <s>leoban<c>\nname: leoban"
    And I insert "s" at the cursor
    Then the contents should be "name: <s>leoban<c>s\nname: leobans"

  Scenario: Mirrors mirror tab stop with content at both ends
    Given there is a snippet with tab trigger "name2" and scope "text.plain" and content
      """
        name: ${1:leoban}\nname: ${1:leoban}
      """
    When I open a new edit tab
    And I replace the contents with "name2<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "name: <s>leoban<c>\nname: leoban"
    And I move the cursor to 10
    And I insert "s" at the cursor
    Then the contents should be "name: leob<c>san\nname: leobsan"
    And I move the cursor to 10
    And I press the Backspace key in the edit tab
    And I press the Backspace key in the edit tab
    Then the contents should be "name: le<c>san\nname: lesan"

  Scenario: Transforms tab stops
    Given there is a snippet with tab trigger "name" and scope "text.plain" and content
      """
        name: $1\nupper: ${1/(\w+)/\U$1\E/}
      """
    When I open a new edit tab
    And I replace the contents with "name<c>"
    And I press the Tab key in the edit tab
    And I insert "raptor" at the cursor
    Then the contents should be "name: <c>raptor\nupper: RAPTOR"
    And I move the cursor to 10
    And I press the Backspace key in the edit tab
    And I press the Backspace key in the edit tab
    Then the contents should be "name: ra<c>or\nupper: RAOR"

  Scenario: Globally transforms tab stops
    Given there is a snippet with tab trigger "name" and scope "text.plain" and content
      """
        name: $1\nupper: ${1/(\w+)/\U$1\E/g}
      """
    When I open a new edit tab
    And I replace the contents with "name<c>"
    And I press the Tab key in the edit tab
    And I insert "raptor blackbird" at the cursor
    Then the contents should be "name: <c>raptor blackbird\nupper: RAPTOR BLACKBIRD"










