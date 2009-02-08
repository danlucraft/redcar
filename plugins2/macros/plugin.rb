
module Redcar
  class MacrosPlugin < Redcar::Plugin
    def self.load(plugin)
      lib("macro")
      command("record_macro_command")
      command("run_macro_command")
      plugin.transition(FreeBASE::LOADED)
    end
  end
end
