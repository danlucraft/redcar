Feature: Command history

Background:
  When I open a new repl
  And I insert "x = 4" at the cursor
  And I press the return key
  Then the current command should be blank
  When I insert "y = 5" at the cursor
  And I press the return key

Scenario: Command History can be browsed using the arrow keys
  When I press the up arrow key
  Then the current command should be "y = 5"
  When I press the up arrow key
  Then the current command should be "x = 4"
  When I press the up arrow key
  Then the current command should be "x = 4"
  When I press the down arrow key
  Then the current command should be "y = 5"
  When I press the down arrow key
  Then the current command should be blank

Scenario: Command history can be cleared from the screen but retained in the buffer
  When I insert "clear" at the cursor
  And I press the return key
  And I press the up arrow key
  Then the current command should be "clear"
  When I press the up arrow key
  Then the current command should be "y = 5"
  When I press the up arrow key
  Then the current command should be "x = 4"

Scenario: Command history can be reset
  When I insert "reset" at the cursor
  And I press the return key
  And I press the up arrow key
  Then the current command should be blank
  And I press the up arrow key
  Then the current command should be blank
  And I press the down arrow key
  Then the current command should be blank

Scenario: Command history is saved between REPL sessions
  When I close the focussed tab
  And I open a new repl
  When I press the up arrow key
  Then the current command should be "y = 5"
  When I press the up arrow key
  Then the current command should be "x = 4"

Scenario: Uncommitted command is saved when navigating history
  When I insert "x - y" at the cursor
  And I press the up arrow key
  Then the current command should be "y = 5"
  When I press the down arrow key
  Then the current command should be "x - y"

Scenario: Command history buffer size can be set
  When I insert "x * y" at the cursor
  And I press the return key
  When I insert "buffer 2" at the cursor
  And I press the return key
  Then the REPL output should be "Buffer size set to 2"
  When I press the up arrow key
  Then the current command should be "buffer 2"
  And I press the up arrow key
  Then the current command should be "x * y"
  And I press the up arrow key
  Then the current command should be "x * y"
  When I press the return key
  And I close the focussed tab
  And I open a new repl
  And I insert "buffer" at the cursor
  And I press the return key
  Then the REPL output should be "Current buffer size is 2"