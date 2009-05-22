
class Redcar::EditView
  class AutoCompleter
    def define_completion_state_machine
      state_machine = Statemachine.build do
        state :no_completion_state do
          event :any_key, :no_completion_state
          event :esc_pressed, :cycling_state, :rebuild_word_list
        end
         
        state :cycling_state do
          on_entry :cycle_completion
          event :esc_pressed, :cycling_state
          event :any_key, :quit_cycling_state
        end
        
        state :quit_cycling_state do
          on_entry :quit_cycling
        end
      end
      
      state_machine.context = AutocompleteCompletionStateContext.new(self, @buf)
      state_machine.context.statemachine = state_machine
      @completion_state = state_machine
    end
    
    class AutocompleteCompletionStateContext
      attr_accessor :statemachine
      
      def initialize(autocompleter, buffer)
        @autocompleter, @buf = autocompleter, buffer
        @i = 0
      end
      
      def cycle_completion
        unless @completions.length == 0
          @i = (@i+1)%@completions.length
          completion = @completions[@i]
          puts "cycling completion: #{@i}: #{}"
          @autocompleter.flag_completion
          @buf.replace_range(@prefix_offsets[0], @prefix_offsets[1], completion)
          word_end_offset = @prefix_offsets[0] + completion.length
          @buf.place_cursor(@buf.iter(word_end_offset))
          @prefix_offsets[1] = word_end_offset
          @autocompleter.flag_completion
        end
      end
      
      def quit_cycling
        @i = 0
        puts "quitting cycling"
        statemachine.state = :no_completion_state
      end

      def rebuild_word_list(prefix, prefix_offsets)
        @prefix, @prefix_offsets = prefix, prefix_offsets
        word_list = @autocompleter.rebuild_word_list
        @completions = word_list.completions(@prefix)
      end
    end
  end
end
