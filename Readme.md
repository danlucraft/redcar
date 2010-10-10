# Code Comments #

---

A code comment shortcut plugin for Redcar.

_Built on TextUtils by William Cherry_


## Installation ##

    cd ~/.redcar/plugins
    git clone git://github.com/kattrali/text-utils.git comment


## Toggle Line Comment ##

Menu: Edit > Formatting > Toggle Block Comment

Shortcut: Ctrl+/

Toggles the current selection from commented-out to uncommented. Each line is checked for the current single-line comment character(s). If the line is currently commented then the comment character is removed, otherwise the line is prepending by the comment character(s).

## Toggle Block Comment ##

Menu: Edit > Formatting > Toggle Block Comment

Shortcut: Ctrl+.

Toggles a comment characters which wrap the current selection or line.


## Extending this Plugin ##

If a particular language isn't supported (yet), you can add support for it by defining the comment characters in a comment_extension.json file in ~/.redcar or [project_path]/.redcar like so:

    {
        "C++": {
            "line_comment" : "//",
            "start_block"  : "/*",
            "end_block"    : "*/"
        },
        "Perl": {
            "line_comment"    : "#"
        }
        ...
    }

and remember to send a pull request for any languages you want to add. :)

## Note ##

* The RSense plugin has the same keymapping as Toggle Line Comment (not sure how to handle this, yet)
* An option to disable the warning when using default comment strings is in the plugin preferences, as well as settings for the defaults