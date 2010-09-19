
module Redcar
  module Macros
    module Predictive
      class SequenceFinder
        MAX_LENGTH = 10
        
        attr_reader :super_sequence 
        
        def initialize(super_sequence)
          @super_sequence = super_sequence
        end
        
        def first
          1.upto(MAX_LENGTH) do |length|
            candidate = super_sequence[0..(length - 1)]
            if candidate == super_sequence[length..(2*length - 1)]
              return candidate.reverse
            end
          end
        end
      end
    end
  end
end