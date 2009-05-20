
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
      
      prefix, offsets = @cursor_state.context.touched_word
      if prefix
        # TODO: if repeatedly called this method should NOT requild the list, but toggle through the available completions, if any
        rebuild_word_list
        puts "completions for #{prefix} (by distance)"
        @word_list.completions(prefix).each do |completion|
          puts completion
        end
      end
    end
    
    def define_completion_state_machine
      
    end
  end
end
