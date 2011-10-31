# Feature: Multiple windows
# 
#   Scenario: Start with one window
#     Then there should be one window
#   
#   Scenario: Open a new window
#     When I open a new window
#     Then there should be 2 windows
#   
#   Scenario: Open two new windows
#     When I open a new window
#     And I open a new window
#     Then there should be 3 windows
# 
#   Scenario Outline: Close a window
#     When I open a new window with title "Second"
#     And I close the window <how>
#     Then there should be one window
#     And the window should be titled "Redcar"
# 
#     Examples:
#       | how             |
#       | with a command  | 
#       | through the gui |
#       
#   Scenario: A new window is focussed
#     When I open a new window with title "Second"
#     And I open a new edit tab
#     Then the window "Second" should have 1 tab
#   
#   Scenario: The focus returns the first window when I close the second
#     When I open a new window with title "Second"
#     And I close the window "Second" through the gui
#     And I open a new edit tab
#     Then the window "Redcar" should have 1 tab
# 
#   Scenario Outline: Can focus on each window
#     When I open a new edit tab
#     And I open a new window with title "Second"
#     And I focus the window "Redcar" <how>
#     And I open a new edit tab
#     Then the window "Redcar" should have 2 tabs
#     Then the window "Second" should have 0 tabs
# 
#     Examples:
#       | how             |
#       | with a command  | 
#       | through the gui |