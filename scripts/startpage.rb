# redcar/scripts/startpage
# D.B. Lucraft

module Redcar
  class StartPage < Plugin
    preferences "General" do |p|
      p.add "Open Page at Start Up", :type => :toggle, :default => :true
    end
    
    Redcar.hook :startup do
      if StartPage.Preferences["Open Page at Start Up"] == "true"
        nt = Redcar.new_tab
        nt.name = "#scratch"
        nt.textview.set_grammar(Redcar::Syntax.grammar(:name => 'Ruby'))
        nt.focus
        nt.contents = "# This is Redcar, scriptable editing for Linux.\n" + 
          "# Copyright Daniel Lucraft 2007\n"+
          "\n#! /usr/bin/env ruby\n\n"+
          "Redcar.startup(:output => \"silent\")"
        nt.cursor = 0
        nt.modified = false
        nt.clear_undo
      end
    end
  end
end

