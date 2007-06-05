# redcar/scripts/startpage
# D.B. Lucraft

Redcar.hook :startup do
  nt = Redcar.new_tab
  nt.name = "#scratch"
  nt.set_grammar(Redcar::Syntax.grammar(:name => 'Ruby'))
  nt.focus
  nt.contents = "# This is Redcar, scriptable editing for Linux.\n" + 
    "# Copyright Daniel Lucraft 2007\n"+
    "\n#! /usr/bin/env ruby\n\n"+
    "Redcar.startup(:output => \"silent\")"
  nt.cursor = 0
  nt.modified = false
  nt.clear_undo
end

