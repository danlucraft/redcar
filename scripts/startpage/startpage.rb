# redcar/scripts/startpage
# D.B. Lucraft

module Redcar
  class StartPage
    include Redcar::Preferences
    
    preference "General/Start Page/Open at start up" do |p|
      p.type = :toggle 
      p.default = true
    end
    
#     Redcar.hook :startup do
#       if StartPage.Preferences["Open Page at Start Up"] == "true"
#         nt = Redcar.new_tab
#         nt.name = "#scratch"
#         nt.textview.set_grammar(Redcar::SyntaxSourceView.grammar(:name => 'Ruby'))
#         nt.focus
#         nt.contents = "# This is Redcar, scriptable editing for Linux.\n" + 
#           "# Copyright Daniel Lucraft 2007\n"+
#           "\n#! /usr/bin/env ruby\n\n"+
#           "Redcar.startup(:output => \"silent\")"
#         nt.cursor = 0
#         nt.modified = false
#       end
#     end
  end
end

