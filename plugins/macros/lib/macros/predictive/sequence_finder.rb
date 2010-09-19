
module Redcar
  module Macros
    module Predictive
      class SequenceFinder
        MAX_LENGTH = 100
        
        attr_reader :super_sequence 
        
        def initialize(super_sequence)
          @super_sequence = super_sequence.reverse
        end
        
        def first
          fully_repeated_sequence or partially_repeated_sequence
        end
        
        def fully_repeated_sequence
          max_possible_repeat_length.downto(1) do |length|
            candidate = super_sequence[0..(length - 1)]
            confirmation = super_sequence[length..(2*length - 1)]
            if candidate == confirmation
              return Sequence.new(candidate.reverse, 0)
            end
          end
          nil
        end
        
        # history looks like: XYX
        def partially_repeated_sequence
          max_possible_repeated_portion_length.downto(1) do |length_x|
            candidate_x = super_sequence[0..(length_x - 1)]
            1.upto(max_possible_non_repeated_portion_length(length_x)) do |length_y|
              candidate_y = super_sequence[length_x..(length_x + length_y - 1)]
              confirmation_x = super_sequence[(length_x + length_y)..(2*length_x + length_y - 1)]
              if candidate_x == confirmation_x
                return Sequence.new(candidate_x.reverse + candidate_y.reverse, candidate_x.length)
              end
            end
          end
          nil
        end
        
        # in XX how long can X be?
        def max_possible_repeat_length
          super_sequence.length / 2
        end
        
        # in XYX how long can X be?
        def max_possible_repeated_portion_length
          r = super_sequence.length / 2
          if r*2 == super_sequence.length
            r - 1
          else
            r
          end
        end
        
        # in XYX how long can Y be, given X?
        def max_possible_non_repeated_portion_length(repeated_portion_length)
          super_sequence.length - repeated_portion_length*2
        end
      end
    end
  end
end