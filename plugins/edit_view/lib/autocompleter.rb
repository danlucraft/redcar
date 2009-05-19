
load File.dirname(__FILE__) + "/autocompleter/word_list.rb"
load File.dirname(__FILE__) + "/autocompleter/autocomplete_iterator.rb"
require 'statemachine'


class Redcar::EditView
  class AutoCompleter
  
    WORD_CHARACTERS = /\w/ # /(\s|\t|\.|\r|\(|\)|,|;)/
    
    def initialize(buffer)
      @buf = buffer
      @parser = buffer.parser
      @word_list = WordList.new
      @autocomplete_iterator = AutocompleteIterator.new(buffer, WORD_CHARACTERS)
      buffer.autocompleter = self
      define_state_machine
      connect_signals
    end
    
    def connect_signals
      connect_mark_set_signal
    end
    
    def connect_mark_set_signal
      @buf.signal_connect("mark_set") do |document, iter, mark|
        if mark == @buf.cursor_mark && @buf.selection.length == 0
          @cursor_state.cursor_moved
        end
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
      puts "complete word in AutoCompleteWord called! yay."
      
      if @cursor_state.context.touching_word
        # TODO: if repeatedly called this method should NOT requild the list, but toggle through the available completions, if any
        rebuild_word_list
        prefix = @cursor_state.context.touched_word
        puts "completions for #{prefix} (by distance)"
        @word_list.completions(prefix).each do |completion|
          puts completion
        end
      end
    end
    
    
    def define_state_machine
      state_machine = Statemachine.build do
        trans :in_word_state, :cursor_moved, :check_word_state # start state, event, target state -> check for touching word
	      trans :not_in_word_state, :cursor_moved, :check_word_state
	      state :check_word_state do
          on_entry :check_for_word
          event :not_in_word, :not_in_word_state
          event :in_word, :in_word_state
        end
      end
      
      state_machine.context = AutocompleteCursorStateContext.new(@buf)
      state_machine.context.statemachine = state_machine
      @cursor_state = state_machine
    end
    
    class AutocompleteCursorStateContext
      attr_accessor :statemachine, :last_cursor_line, :touched_word
      
      def initialize(doc)
        @last_cursor_line = -1
        @document = doc
        puts @document.inspect
      end
      
      def touching_word
        return nil if @touched_word.length == 0
        return @touched_word
      end
      
      private
      def check_for_word
        @touched_word = word_touching_cursor
        if @touched_word.length == 0
          @statemachine.not_in_word
        else
          @statemachine.in_word
        end
      end
      
      # returns the word (see WORD_CHARACTERS) that the cursor is currently touching.
      # nil otherwise.
      def word_touching_cursor
        @line = @document.get_line
        left, right = word_range
        @document.get_slice(@document.iter(left), @document.iter(right))
      end
      
      # returns the range that holds the current word (depending on WORD_CHARACTERS)
      def word_range
        left = @document.cursor_line_offset - 1
        right = @document.cursor_line_offset
        left_range = 0
        right_range = 0
        offset = @document.cursor_offset
        
        until left == -1 || WORD_CHARACTERS !~ (@line[left].chr)
          left -= 1
          left_range -= 1
        end
        
        until right == @line.length || WORD_CHARACTERS !~ (@line[right].chr)
          right += 1
          right_range += 1
        end
        return [offset+left_range, offset+right_range]
      end
    end 
  end
end
