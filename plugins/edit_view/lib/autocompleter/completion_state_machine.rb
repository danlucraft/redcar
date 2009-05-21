
class Redcar::EditView
  class AutoCompleter
    def define_completion_state_machine
      state_machine = Statemachine.build do
        trans :no_completion_state, :any_key, :no_completion_state
        trans :no_completion_state, :esc_pressed, :rebuild_word_list_state
        
        state :rebuild_word_list_state do
          on_entry :rebuild_word_list
          event :start_cycling, :cycling_state
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
      
      state_machine.context = AutocompleteCompletionStateContext.new(self)
      state_machine.context.statemachine = state_machine
      @completion_state = state_machine
    end
    
    class AutocompleteCompletionStateContext
      attr_accessor :statemachine
      
      def initialize(autocompleter)
        @autocompleter = autocompleter
        @i = 0
      end
      
      def cycle_completion
        unless @completions.length == 0
          @i = (@i+1)%@completions.length
          puts "cycling completion: #{@i}: #{@completions[@i]}"
        end
      end
      
      def quit_cycling
        @i = 0
        puts "quitting cycling"
        statemachine.state = :no_completion_state
      end
      
      def rebuild_word_list
        @word_list = @autocompleter.rebuild_word_list
        @completions = @word_list.completions(@autocompleter.prefix)
        statemachine.start_cycling
      end
    end
  end
end
