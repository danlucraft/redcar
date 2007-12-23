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
      
      command "startpage/display" do |c|
        c.menu = "Tools/Display Startpage"
        c.icon = :CUT
        c.command %q{
          nt = Redcar.new_tab
          nt.name = "#scratch"
          nt.textview.set_grammar(Redcar::SyntaxSourceView.grammar(:name => 'Ruby'))
          nt.focus
          nt.contents = "# This is Redcar, scriptable editing for Linux.\\n" + 
                        "# Copyright Daniel Lucraft 2008\\n"+
                        "# \\n# In Redcar, the super key is the 'Windows' key, usually next to Alt."
          nt.cursor = 0
          nt.modified = false
        }
      end
      
#       menu "Tools/Display Startpage" do |m|
#         m.command = :startpage
#         m.icon    = :CUT
#       end
      
      def self.load(plugin)
        if Redcar.preferences("General/Start Page/Open at start up").to_bool
          Redcar.hook :startup do 
            p :sat
            Redcar::Command.execute('startpage/display')
          end
        end
        plugin.transition(FreeBASE::LOADED)
      end
    end
  end
end

