# Text Utils #

---

A simple collection of text utilites for Redcar.




## Toggle Block Comment ##

Menu: Edit > Toggle Block Comment

Shortcut: Ctrl+/

Toggles the current selection from commented-out to uncommented. Each line is checked for the current single-line comment character(s). If the line is currently commented then the comment character is removed, otherwise the line is prepending by the comment character(s).


### TODO ###
1. Currently each line that is commented or uncommented is treated as an individual undoable operation instead of just one for the whole operation. This should be fixed.
2. Should look at the majority of lines to determine if the user want to comment or uncomment.
3. Needs to implement better bundle handling so that we can look up the comment characters from the bundles instead of having them hard-coded.





