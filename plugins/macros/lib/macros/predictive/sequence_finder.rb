
module Redcar
  module Macros
    module Predictive
      class SequenceFinder
        MAX_LENGTH = 100
        
        attr_reader :super_sequence
        attr_reader :state
        
        def initialize(super_sequence)
          @super_sequence = super_sequence.reverse
          @state          = {
            :search_mode => :fully_repeated, 
            :length_x => max_possible_repeat_length,
            :length_y => nil
          }
        end
          
        def next
          return nil if done?
          seq = nil
          until seq or done?
            seq = detect_current
            increment_state
          end
          seq
        end
        
        def detect_current
          case current_search_mode
          when :fully_repeated
            detect_fully_repeated_sequence(state[:length_x])
          when :partially_repeated
            detect_partially_repeated_sequence(state[:length_x], state[:length_y])
          end
        end
        
        def done?
          @done
        end
        
        def current_search_mode
          @state[:search_mode]
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
        
        private
        
        def detect_fully_repeated_sequence(length)
          candidate = super_sequence[0..(length - 1)]
          confirmation = super_sequence[length..(2*length - 1)]
          if candidate == confirmation
            ActionSequence.new(candidate.reverse, 0)
          end
        end
        
        def detect_partially_repeated_sequence(length_x, length_y)
          candidate_x = super_sequence[0..(length_x - 1)]
          candidate_y = super_sequence[length_x..(length_x + length_y - 1)]
          confirmation_x = super_sequence[(length_x + length_y)..(2*length_x + length_y - 1)]
          if candidate_x == confirmation_x
            ActionSequence.new(candidate_x.reverse + candidate_y.reverse, candidate_x.length)
          end
        end
        
        def increment_state
          case current_search_mode
          when :fully_repeated
            if state[:length_x] > 1
              state[:length_x] -= 1
            else
              state[:search_mode] = :partially_repeated
              state[:length_x]    = max_possible_repeated_portion_length
              state[:length_y]    = 1
            end
          when :partially_repeated
            if state[:length_y] == max_possible_non_repeated_portion_length(state[:length_x])
              state[:length_y] = 1
              if state[:length_x] > 1
                state[:length_x] -= 1
              else
                @done = true
              end
            else
              state[:length_y] += 1
            end
          end
        end
      end
    end
  end
end