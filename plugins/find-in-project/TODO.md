* Add a spinner to the left of the search button to indicate that search is going
* Remember literal match, match case, and with context settings
* Better handle long lines (wrapping)
* Per-project settings
* Speed it up! (in particular, with context). Stats below.

Searching for "redcar" in the Redcar source code:
  - Without Context:
    - Textmate AckMate: ~2 seconds
    - Redcar find-in-project: ~50 seconds
  - With Context:
    - Textmate AckMate: ~4 seconds
    - Redcar find-in-project: ~5 minutes
