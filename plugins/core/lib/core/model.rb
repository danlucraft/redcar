module Redcar
  module Model
    attr_reader :controller
    
    def controller=(controller)
      @controller = controller
    end
  end
end