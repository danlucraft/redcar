
require 'vte'

module Redcar
  class Shell < Plugin
    preferences "Shell" do |p|
      p.add("Default Shell Command", :type => :string, :default => "bash")
    end
    
    Redcar.menu("Tools") do |menu|
      menu.command("Open Shell", :open_shell, nil, nil) do
        Redcar.new_tab(NewShellTab).focus
      end
    end
    
    class NewShellTab < Tab
      def initialize(pane)
        vte = Vte::Terminal.new
        vte.show
        super(pane, vte)
        vte.fork_command(Shell.Preferences["Default Shell Command"])
      end
    end
  end
end
