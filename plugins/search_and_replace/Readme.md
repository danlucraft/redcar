Readme
===

The Search and Replace plugin provides search and replace capablites to Redcar. 
To use the Search and replace plugin select Search and Repleace from the Edit menu.  

Installation Instructions
---
1. Clone the repoistory using git into the ~/.redcar/plugins directory
1. Start Redcar

Usage Instructions
---
The Search and Replace speedbar can be accessed by selecting Search and Replace from 
the Edit menu. Once selected a new speedbar should be displayed.


Currently implemented
---
1. Command class and menu entry
1. Implement search and replace - replaces first one without prompt
1. Implement search and replace all - even eiaser then single 
1. Make undoable - provided by Redcar itself, nothing to implement.
1. Prettfy UI - got rid of the clunky dialog box
1. Provide options to select the type of search (regex, glob, plain)
1. Refactor code - broke code up by functional concern
1. Use the same search methodlogy as Search - Search current line, rest of lines, and then from start of file.

Todo List
---
1. Store last n search and replace results in memory
1. Optionally store the search and replace results in configuration file.
1. Pre-populate seach box with selected text
1. Adding a shortcut keystroke.
1. Better error handling
1. Advanced Search and Replace - Across all open files or across all files in a project 
1. RSpec Tests
1. Regex handling for replace (groups, etc..)
1. Fix same line bug - doesn't go back and seach to left of cursor.

Comments or suggestions wcherry69@gmail.com