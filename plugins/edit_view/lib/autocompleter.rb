
load File.dirname(__FILE__) + "/autocompleter/word_list.rb"
load File.dirname(__FILE__) + "/autocompleter/autocomplete_iterator.rb"
require 'statemachine'


class Redcar::EditView
  class AutoCompleter
  
    # TODO: maybe this should be based on the grammar of the language
    # that is active in order to make this as flexible as possible...
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
      connect_insert_text_signal
      connect_delete_range_signal
      @buf.signal_connect("mark_set") do |document, iter, mark|
        if mark == @buf.cursor_mark
          @state.cursor_moved
          # TODO: rebuilding word list doesn't actually have to occur here. updating the word offsets will do as well
          rebuild_word_list
        end
      end
    end
    
    def connect_insert_text_signal
      @buf.signal_connect("insert_text") do |document,iter,text,length|
        rebuild_word_list
      end
    end
        
    def connect_delete_range_signal
      @buf.signal_connect("delete_range") do |document, iter1, iter2|
        rebuild_word_list
      end
    end
    
    # rebuild the list of words from scratch
    def rebuild_word_list
      cursor_offset = @buf.cursor_offset
      @word_list = WordList.new
      @word_list.cursor_offset = cursor_offset
      
      @autocomplete_iterator.each_word_with_offset do |word, offset|
        distance = (offset - cursor_offset).abs
        @word_list.add_word(word, distance)
      end
      
      # TODO: remove this debug output
      @word_list.each do |word, distance|
        puts word.ljust(20) + distance.to_s
      end
    end
    
    
    def update_word_list_cursor_offset
      # @word_list.cursor_offset = @buf.cursor_offset
      # TODO: this method should update the word_list cursor offset
    end

    def complete_word
      puts "complete word in AutoCompleteWord called! yay."
      prefix = @state.context.touched_word
      
      puts "completions for #{prefix} (by distance)"
      @word_list.completions(prefix).each do |completion|
        puts completion
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
      
      state_machine.context = AutocompleteStateContext.new(@buf)
      state_machine.context.statemachine = state_machine
      @state = state_machine
    end
    
    class AutocompleteStateContext
      attr_accessor :statemachine, :last_cursor_line, :touched_word
      
      def initialize(doc)
        @last_cursor_line = -1
        @document = doc
        puts @document.inspect
      end
      
      def check_for_word
        @touched_word = word_touching_cursor
        if @touched_word.length == 0
          @statemachine.not_in_word
          puts "out of word"
        else
          @statemachine.in_word
          puts "in word {#{@touched_word}}"
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
