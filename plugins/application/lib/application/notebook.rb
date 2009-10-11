module Redcar
  class Notebook
    include Redcar::Model
    include Redcar::Observable
    
    attr_reader :tabs
    
    def initialize
      @tabs = []
    end
    
    def length
      @tabs.length
    end
    
    def <<(tab)
      @tabs << tab
      controller.tab_added(tab)
    end
  end
end
