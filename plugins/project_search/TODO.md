* Speed up regex search (in particular, with context). Stats below.

Searching for "redcar" in the Redcar source code:
  - Without Context:
    - Textmate AckMate: ~2 seconds
    - Redcar regex search: ~50 seconds
  - With Context:
    - Textmate AckMate: ~4 seconds
    - Redcar regex search: ~5 minutes

* Per-project settings
