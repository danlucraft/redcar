module Redcar
  class Quit < Redcar::Command
    key "Alt+F4"
    icon :QUIT
    
    def execute
      Redcar::App.quit
    end
  end
end

