
# require 'vte'

# module Redcar
#   class Shell < Plugin
# #     preference "Shell" do |p|
# #       p.add("Default Shell Command", :type => :string, :default => "bash")
# #     end
    
#     class NewShellTab < Tab
#       def initialize(pane)
#         vte = Vte::Terminal.new
#         vte.show
#         super(pane, vte)
#         vte.fork_command(Shell.Preferences["Default Shell Command"])
#       end
#     end
#   end
# end
