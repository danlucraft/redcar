
require 'statemachine'

load File.dirname(__FILE__) + "/autocompleter/word_list.rb"
load File.dirname(__FILE__) + "/autocompleter/autocomplete_iterator.rb"
load File.dirname(__FILE__) + "/autocompleter/cursor_state_machine.rb"

class Redcar::EditView
  class AutoCompleter
  
    WORD_CHARACTERS = /\w/ # /(\s|\t|\.|\r|\(|\)|,|;)/
    
    def initialize(buffer)
      @buf = buffer
      @parser = buffer.parser
      @word_list = WordList.new
      @autocomplete_iterator = AutocompleteIterator.new(buffer, WORD_CHARACTERS)
      buffer.autocompleter = self
      define_cursor_state_machine
      define_completion_state_machine      
      connect_signals
    end
    
    def connect_signals
      connect_mark_set_signal
      connect_insert_text_signal
    end
    
    def connect_mark_set_signal
      @buf.signal_connect("mark_set") do |document, iter, mark|
        if mark == @buf.cursor_mark && @buf.selection.length == 0
          @cursor_state.cursor_moved
          @completion_state.any_key
        end
      end
    end
    
    def connect_insert_text_signal
      @buf.signal_connect("insert_text") do |document, iter, text, length|
        @completion_state.any_key
      end
    end
    
    # rebuild the list of words from scratch
    def rebuild_word_list
      cursor_offset = @buf.cursor_offset
      @word_list = WordList.new
      
      @autocomplete_iterator.each_word_with_offset do |word, offset|
        distance = (offset - cursor_offset).abs
        @word_list.add_word(word, distance)
      end
    end
    
    def complete_word
      prefix, offsets = @cursor_state.context.touched_word
      if prefix
        # TODO: if repeatedly called this method should NOT requild the list, but toggle through the available completions, if any
        @completion_state.esc_pressed
        
        rebuild_word_list
        puts "completions for #{prefix} (by distance)"
        @word_list.completions(prefix).each do |completion|
          puts completion
        end
      end
    end
    
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
      
      state_machine.context = AutocompleteCompletionStateContext.new
      state_machine.context.statemachine = state_machine
      @completion_state = state_machine
    end
    
    class AutocompleteCompletionStateContext
      attr_accessor :statemachine
      
      def initialize
        @i = 0
      end
      
      def cycle_completion
        @i += 1
        puts "cycling completion: #{@i}"
      end
      
      def quit_cycling
        @i = 0
        puts "quitting cycling"
        statemachine.state = :no_completion_state
      end
      
      def rebuild_word_list
        statemachine.start_cycling
      end
    end
  end
end
