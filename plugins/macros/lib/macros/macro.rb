
module Redcar
  class Macro
    attr_accessor :actions, name
    
    def initialize(actions, name="Nameless Macro :(")
      @actions = actions
      @name = name
    end
  end
end
