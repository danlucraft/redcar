# redcar/scripts/startpage
# D.B. Lucraft

Redcar.hook :startup do
  nt = Redcar.new_tab
  nt.name = "#scratch"
  nt.focus
  nt.contents = "# This is Redcar, scriptable editing for Linux.\n" + 
    "# Copyright Daniel Lucraft 2007"
  nt.cursor = 0
  nt.modified = false
  nt.clear_undo
end

