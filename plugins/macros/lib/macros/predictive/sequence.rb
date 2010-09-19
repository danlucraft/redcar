
module Redcar
  module Macros
    module Predictive
      class Sequence
        attr_reader :actions
        attr_reader :skip_length
        
        def initialize(actions, skip_length)
          @actions = actions
          @skip_length = skip_length
        end
      end
    end
  end
end