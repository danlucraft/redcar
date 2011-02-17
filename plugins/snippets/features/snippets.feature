Feature: Snippets

  Background:
    When I open a new edit tab
    And tabs are hard

  Scenario: Simple content snippet in global scope
    Given there is a snippet with tab trigger "DBL" and scope "" and content
      """
        Daniel Benjamin Lucraft
      """
    When I replace the contents with "DBL<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "Daniel Benjamin Lucraft<c>"

  Scenario: Snippet text preceded by other characters and separated by non-word characters
    Given there is a snippet with tab trigger "ewf" and scope "" and content
      """
        Earth, Wind, and Fire
      """
    When I replace the contents with "}}ewf<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "}}Earth, Wind, and Fire<c>"
    When I replace the contents with "(1,2,4)}}ewf<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "(1,2,4)}}Earth, Wind, and Fire<c>"
    When I replace the contents with "blank.test1.ewf<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "blank.test1.Earth, Wind, and Fire<c>"

  Scenario: Simple content snippet in plain text scope
    Given there is a snippet with tab trigger "DBL" and scope "text.plain" and content
      """
        Daniel Benjamin Lucraft
      """
    When I replace the contents with "DBL<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "Daniel Benjamin Lucraft<c>"

  Scenario: Inserts Textmate environment variable TM_LINE_INDEX
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix ${TM_LINE_INDEX} Gaeta
      """
    When I replace the contents with "0123 fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "0123 Felix 5 Gaeta<c>"

  Scenario: Inserts Textmate environment variable TM_LINE_INDEX without curlies
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix $TM_LINE_INDEX Gaeta
      """
    When I replace the contents with "0123 fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "0123 Felix 5 Gaeta<c>"

  Scenario: Transforms Textmate environment variables
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix ${TM_CURRENT_LINE/Co/ChiefOfStaff/} Gaeta
      """
    When I replace the contents with "CoABC fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "CoABC Felix ChiefOfStaffABC  Gaeta<c>"

  Scenario: Transforms Textmate environment variables global find and replace
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix ${TM_CURRENT_LINE/\w/CS /g} Gaeta
      """
    When I replace the contents with "ABC fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "ABC Felix CS CS CS   Gaeta<c>"

  Scenario: Transforms Textmate environment variables escapes characters
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix ${TM_CURRENT_LINE/\w/C\/S /g} Gaeta
      """
    When I replace the contents with "ABC fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "ABC Felix C/S C/S C/S   Gaeta<c>"

  Scenario: Inserts one tab stop
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t\nend
      """
    When I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "if <c>\n\t\nend"

  Scenario: Escapes dollars
    Given there is a snippet with tab trigger "DBL" and scope "text.plain" and content
      """
        Daniel \$1 Benjamin Lucraft
      """
    When I replace the contents with "DBL<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "Daniel $1 Benjamin Lucraft<c>"

  Scenario: Selects tab stop zero
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if ${0:instance}
      """
    When I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "if <s>instance<c>"

  Scenario: Allows tabbing past snippet
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t\nend
      """
    When I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    And I press the Tab key in the edit tab
    Then the contents should be "if \n\t\nend<c>"

  Scenario: Allows tabbing between tab stops
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t$2\nend
      """
    When I replace the contents with "if<c>"
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
    When I replace the contents with "if<c>"
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
    When I replace the contents with "if<c>"
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
    When I replace the contents with "if<c>"
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
    When I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "if <s>condition<c>\n\t\nend"

  Scenario: Inserts environment variable as placeholder
    Given there is a snippet with tab trigger "fg" and scope "text.plain" and content
      """
        Felix ${1:$TM_LINE_INDEX} Gaeta
      """
    When I replace the contents with "ABC fg<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "ABC Felix 4 Gaeta"

  Scenario: Does not trigger snippet on tab trigger with trailing space
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if ${1:condition}\n\t$0\nend
      """
    When I replace the contents with "ABC if <c>"
    And I press the Tab key in the edit tab
    And I move the cursor to 0
    And I press the Tab key in the edit tab
    Then the contents should not be "\t<c>ABC if condition\n\t\nend"
    And the contents should be "\t<c>ABC if \t"

  Scenario: Leaves snippet on cursor move
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if ${1:condition}\n\t$0\nend
      """
    When I replace the contents with "ABC if<c>"
    And I press the Tab key in the edit tab
    And I move the cursor to 0
    And I press the Tab key in the edit tab
    Then the contents should be "\t<c>ABC if condition\n\t\nend"

  Scenario: Multiple tab stops with content
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if ${1:condition}\n\t${2:code}\nend
      """
    When I replace the contents with "if<c>"
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
    When I replace the contents with "name2<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "name: <c>\nname: "
    And I insert "raider" at the cursor
    Then the contents should be "name: <c>raider\nname: raider"

  Scenario: Mirrors mirror tab stop with content
    Given there is a snippet with tab trigger "name2" and scope "text.plain" and content
      """
        name: ${1:leoban}\nname: $1
      """
    When I replace the contents with "name2<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "name: <s>leoban<c>\nname: leoban"
    And I insert "s" at the cursor
    Then the contents should be "name: <s>leoban<c>s\nname: leobans"

  Scenario: Mirrors mirror tab stop with content at both ends
    Given there is a snippet with tab trigger "name2" and scope "text.plain" and content
      """
        name: ${1:leoban}\nname: ${1:leoban}
      """
    When I replace the contents with "name2<c>"
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
    When I replace the contents with "name<c>"
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
    When I replace the contents with "name<c>"
    And I press the Tab key in the edit tab
    And I insert "raptor blackbird" at the cursor
    Then the contents should be "name: <c>raptor blackbird\nupper: RAPTOR BLACKBIRD"

  Scenario: Nested tab stops
    Given there is a snippet with tab trigger "hash" and scope "text.plain" and content
      """
        :${1:key} => ${2:"${3:value}"}${4:, }
      """
    When I replace the contents with "hash<c>"
    And I press the Tab key in the edit tab
    Then the contents should be ":<s>key<c> => \"value\", "
    And I press the Tab key in the edit tab
    Then the contents should be ":key => <s>\"value\"<c>, "
    And I press the Tab key in the edit tab
    Then the contents should be ":key => \"<s>value<c>\", "
    And I insert "s" at the cursor
    Then the contents should be ":key => \"<s>value<c>s\", "
    And I press Shift+Tab in the edit tab
    Then the contents should be ":key => <s>\"values\"<c>, "

  Scenario: Very nested tab stops
    Given there is a snippet with tab trigger "hash" and scope "text.plain" and content
      """
        :${1:key} => ${2:"${3:value ${4:is} 3}"}${5:, }
      """
    When I replace the contents with "hash<c>"
    And I press the Tab key in the edit tab
    Then the contents should be ":<s>key<c> => \"value is 3\", "
    When I press the Tab key in the edit tab
    Then the contents should be ":key => <s>\"value is 3\"<c>, "
    When I press the Tab key in the edit tab
    Then the contents should be ":key => \"<s>value is 3<c>\", "
    When I press the Tab key in the edit tab
    Then the contents should be ":key => \"value <s>is<c> 3\", "
    When I press the Tab key in the edit tab
    Then the contents should be ":key => \"value is 3\"<s>, <c>"
    When I press Shift+Tab in the edit tab
    Then the contents should be ":key => \"value <s>is<c> 3\", "
    When I press Shift+Tab in the edit tab
    Then the contents should be ":key => \"<s>value is 3<c>\", "
    When I press Shift+Tab in the edit tab
    Then the contents should be ":key => <s>\"value is 3\"<c>, "
    When I press Shift+Tab in the edit tab
    Then the contents should be ":<s>key<c> => \"value is 3\", "

  Scenario: Latex snippet
    Given there is a snippet with tab trigger "list" and scope "text.plain" and content
      """
        \begin{${1:env}}\n\t${1/(enumerate|itemize|list)|(description)|.*/(?1:\item )(?2:\item)/}$0\n\end{${1:env}}
      """
    When I replace the contents with "list<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "\begin{<s>env<c>}\n\t\n\end{env}"
    When I replace 7 to 10 with "list"
    Then the contents should be "\begin{list<c>}\n\t\item \n\end{list}"
    And I press the Tab key in the edit tab
    Then the contents should be "\begin{list}\n\t\item <c>\n\end{list}"

  Scenario: Transformations do not move cursor
    Given there is a snippet with tab trigger "def" and scope "text.plain" and content
      """
        def $1${1/.+/\"\"\"/}
      """
    When I replace the contents with "def<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "def <c>"
    And I insert "a" at the cursor
    Then the contents should be "def <c>a\"\"\""

  Scenario: Abutting dollars
    Given there is a snippet with tab trigger "def" and scope "text.plain" and content
      """
        def ${1:fname} ${3:docstring for $1}${3/.+/\"\"\"\n/}
      """
    When I replace the contents with "def<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "def <s>fname<c> docstring for fname\"\"\"\n"
    When I replace 4 to 9 with ""
    Then the contents should be "def <c> docstring for \"\"\"\n"

  Scenario: Abutting dollars 2
    Given there is a snippet with tab trigger "def" and scope "text.plain" and content
      """
        def ${1:fname} ${3:docstring for $1}${3/.+/\"\"\"\n/}${3/.+/\t/}${0:pass}
      """
    When I replace the contents with "def<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "def <s>fname<c> docstring for fname\"\"\"\n\tpass"
    When I replace 4 to 9 with ""
    Then the contents should be "def <c> docstring for \"\"\"\n\tpass"
    When I insert "m" at the cursor
    Then the contents should be "def <c>m docstring for m\"\"\"\n\tpass"
    And I press the Tab key in the edit tab
    Then the contents should be "def m <s>docstring for m<c>\"\"\"\n\tpass"
    When I insert "a" at the cursor
    When I replace 6 to 21 with ""
    Then the contents should be "def m <c>a\"\"\"\n\tpass"
    When I insert "b" at the cursor
    Then the contents should be "def m <c>ba\"\"\"\n\tpass"

  Scenario: Enclosing transformations
    Given there is a snippet with tab trigger "def" and scope "text.plain" and content
      """
        def i${3/(^.*?\S.*)|.*/(?1:\()/}${3:args}${3/(^.*?\S.*)|.*/(?1:\))/}
      """
    When I replace the contents with "def<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "def i(<s>args<c>)"
    When I replace 6 to 10 with "foo"
    Then the contents should be "def i(foo)"


