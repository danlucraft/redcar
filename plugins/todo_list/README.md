#Todo List Plugin for Redcar

This adds a simple 'todo list' populated from tags in the code, like 'TODO','IMPROVE','NOTE', etc.

Tags and other settings can be configured from Plugins > Edit Preferences in the Redcar menu.

##Todo List Settings

_included suffixes:_ The suffixes of all files to be included in search for todo tags
 * Defaults to .rb .java .js .erb .groovy .gsp and .html

_excluded files:_ Files to ignore
 * Defaults to jquery.js and prototype.js

_excluded dirs:_ Directories to ignore. 
* Defaults to .svn and .git

_require_colon:_ Whether or not a tag required a colon to be included in tag list.
 * Defaults to true

_tags:_ tags to be searched for in files. 
 * Defaults to TODO NOTE CHANGED OPTIMIZE and IMPROVE
