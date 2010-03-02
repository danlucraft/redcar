Feature: Snippets should indent correctly

  Scenario: Indent level 0, hard
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t\nend
      """
    When I open a new edit tab
    And tabs are hard
    And I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "if <c>\n\t\nend"
    
  Scenario: Indent level 1, hard
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t\nend
      """
    When I open a new edit tab
    And tabs are hard
    And I replace the contents with "\tif<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "\tif <c>\n\t\t\n\tend"
    
  Scenario: Indent level 2, hard
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t\nend
      """
    When I open a new edit tab
    And tabs are hard
    And I replace the contents with "\t\tif<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "\t\tif <c>\n\t\t\t\n\t\tend"
    
  Scenario: Indent level 0, soft
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t$2\nend
      """
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "if<c>"
    And I press the Tab key in the edit tab
    And I press the Tab key in the edit tab
    Then the contents should be "if \n    <c>\nend"
    
  Scenario: Indent level 1, soft
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t\nend
      """
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "    if<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "    if <c>\n        \n    end"
    
  Scenario: Indent level 2, soft
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t\nend
      """
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "        if<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "        if <c>\n            \n        end"
    
  Scenario: Indent level 1, mixed
    Given there is a snippet with tab trigger "if" and scope "text.plain" and content
      """
        if $1\n\t\nend
      """
    When I open a new edit tab
    And tabs are soft, 4 spaces
    And I replace the contents with "  \tif<c>"
    And I press the Tab key in the edit tab
    Then the contents should be "  \tif <c>\n        \n    end"
    
    
    
    
    
    
    
    