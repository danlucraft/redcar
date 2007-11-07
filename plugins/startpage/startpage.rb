# redcar/scripts/startpage
# D.B. Lucraft

module Redcar
  module Plugins
    module StartPage
      extend FreeBASE::StandardPlugin
      extend Redcar::PreferencesBuilder
      extend Redcar::MenuBuilder
      extend Redcar::CommandBuilder
    
      preference "General/Start Page/Open at start up" do |p|
        p.type = :toggle 
        p.default = true
      end
      
      command :startpage do |c|
        c.menu = "Tools/Display Startpage"
        c.icon = :CUT
        c.command =<<-RUBY
          nt = Redcar.new_tab
          nt.name = "#scratch"
          nt.textview.set_grammar(Redcar::SyntaxSourceView.grammar(:name => 'Ruby'))
          nt.focus
          nt.contents = "# This is Redcar, scriptable editing for Linux.\\n" + 
                        "# Copyright Daniel Lucraft 2007\\n"+
                        "\\n#! /usr/bin/env ruby\\n\\n"+
                        "Redcar.startup(:output => \\"silent\\")"
          nt.cursor = 0
          nt.modified = false
        RUBY
      end
      
#       menu "Tools/Display Startpage" do |m|
#         m.command = :startpage
#         m.icon    = :CUT
#       end
      
      def self.start(plugin)
        if Redcar.preferences("General/Start Page/Open at start up")
        end
        plugin.transition(FreeBASE::RUNNING)
      end
    end
  end
end

