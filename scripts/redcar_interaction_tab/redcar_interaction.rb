
module Redcar
  class RedcarInteractionTab < ShellTab
    def initialize(pane)
      @commands = 0
      super("Redcar Interaction Shell\n", pane)
    end
    
    def execute(command)
      @commands += 1
      p :executing_command
      begin
        result = eval(command)
        output("=> "+result.inspect)
      rescue Object => ex
        output(ex.to_s)
      end
    end
    
    def prompt
      "ris:#{@commands}>> "
    end
  end
end
