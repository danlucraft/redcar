module Redcar
  class UnifyAll < Redcar::Command
    key "Ctrl+1"
    norecord
    
    def execute
      win.unify_all
    end
  end
end
