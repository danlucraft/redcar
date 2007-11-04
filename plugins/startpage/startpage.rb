# redcar/scripts/startpage
# D.B. Lucraft

module Redcar
  module Plugins
    module StartPage
      extend FreeBASE::StandardPlugin
      include Redcar::Preferences
    
      preference "General/Start Page/Open at start up" do |p|
        p.type = :toggle 
        p.default = true
      end
    
      def self.start(plugin)
        if Redcar.preferences("General/Start Page/Open at start up")
          nt = Redcar.new_tab
          nt.name = "#scratch"
          nt.textview.set_grammar(Redcar::SyntaxSourceView.grammar(:name => 'Ruby'))
          nt.focus
          nt.contents = "# This is Redcar, scriptable editing for Linux.\n" + 
            "# Copyright Daniel Lucraft 2007\n"+
            "\n#! /usr/bin/env ruby\n\n"+
            "Redcar.startup(:output => \"silent\")"
          nt.cursor = 0
          nt.modified = false
          plugin.transition(FreeBASE::RUNNING)
        end
      end
    end
  end
end

