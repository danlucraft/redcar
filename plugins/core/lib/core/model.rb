module Redcar
  module Model
    include Redcar::ReentryHelpers
    
    attr_reader :controller
    
    def controller=(controller)
      @controller = controller
    end
  end
end