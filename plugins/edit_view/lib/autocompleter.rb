
load File.dirname(__FILE__) + "/autocompleter/prefix_tree.rb"
require 'statemachine'


class Redcar::EditView
  class AutoCompleter
  
    # TODO: maybe this should be based on the grammar of the language
    # that is active in order to make this as flexible as possible...
    WORD_BOUNDARIES = /\w/ # /(\s|\t|\.|\r|\(|\)|,|;)/
    
    def initialize(buffer)
      @buf = buffer
      
      @parser = buffer.parser
      buffer.autocompleter = self
      define_state_machine
      connect_signals
    end
    
    def connect_signals
      #connect_insert_text_signal
      #connect_delete_range_signal
      @buf.signal_connect("mark_set") do |document, iter, mark|
        if mark == @buf.cursor_mark
          @state.cursor_moved
        end
      end
    end
    
    def connect_insert_text_signal
      @buf.signal_connect("insert_text") do |document,iter,text,length|
        
      end
    end
        
    def connect_delete_range_signal
      @buf.signal_connect("delete_range") do |document, iter1, iter2|
        
      end
    end
    
    def multiple_characters_typed(text)
      
    end
        
    def complete_word
      puts "complete word in AutoCompleteWord called! yay."
      @word_before_cursor = @buf.word_before_cursor
      puts @word_before_cursor
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
      attr_accessor :statemachine
      
      def initialize(doc)
        @last_cursor_line = -1
        @document = doc
        puts @document.inspect
      end
      
      def check_for_word
        touched_word = word_touching_cursor
        if touched_word.length == 0
          @statemachine.not_in_word
          puts "out of word"
        else
          @statemachine.in_word
          puts "in word {#{touched_word}}"
        end
      end
      
      # returns the word (see WORD_BOUNDARIES) that the cursor is currently touching.
      # nil otherwise.
      def word_touching_cursor
        unless @document.cursor_line == @last_cursor_line
          @line = @document.get_line
          @last_cursor_line = @document.cursor_line
        end
        left, right = word_range
        @document.get_slice(@document.iter(left), @document.iter(right))
      end
      
      # returns the range that holds the current word (depending on WORD_BOUNDARIES)
      def word_range
        left = @document.cursor_line_offset - 1
        right = @document.cursor_line_offset
        left_range = 0
        right_range = 0
        offset = @document.cursor_offset
        
        until left == -1 || WORD_BOUNDARIES !~ (@line[left].chr)
          left -= 1
          left_range -= 1
        end
        
        until right == @line.length || WORD_BOUNDARIES !~ (@line[right].chr)
          right += 1
          right_range += 1
        end
        return [offset+left_range, offset+right_range]
      end
    end 
  end
end
