require 'statemachine'

load File.dirname(__FILE__) + "/autocompleter/word_list.rb"
load File.dirname(__FILE__) + "/autocompleter/autocomplete_iterator.rb"
# these get monkey-patched into the AutoCompleter class!
load File.dirname(__FILE__) + "/autocompleter/cursor_state_machine.rb"
load File.dirname(__FILE__) + "/autocompleter/completion_state_machine.rb"

class Redcar::EditView
  class AutoCompleter
    
    WORD_CHARACTERS = /:|@|\w/ # /(\s|\t|\.|\r|\(|\)|,|;)/
    
    attr_accessor :prefix, :prefix_offsets
    
    def initialize(buffer)
      @buf = buffer
      @parser = buffer.parser
      @completion_flagged = false
      @autocomplete_iterator = AutocompleteIterator.new(buffer, WORD_CHARACTERS)
      buffer.autocompleter = self
      define_cursor_state_machine
      define_completion_state_machine      
      connect_signals
    end
    
    def connect_signals
      connect_mark_set_signal
      connect_changed_signal
    end
    
    def connect_mark_set_signal
      @buf.signal_connect("mark_set") do |document, iter, mark|
        if mark == @buf.cursor_mark && @buf.selection.length == 0 && !@completion_flagged
          @cursor_state.cursor_moved
          @completion_state.any_key
        end
      end
    end
    
    def connect_changed_signal
      @buf.signal_connect("changed") do |document, iter, text, length|
        # TODO: this IS kinda ugly, but the signal will also get fired while we're completing...
        unless @completion_flagged
          @completion_state.any_key
        end
      end
    end
    
    # rebuild the list of words from scratch
    def rebuild_word_list
      cursor_offset = @buf.cursor_offset
      word_list = WordList.new
      
      @autocomplete_iterator.each_word_with_offset do |word, offset|
        distance = (offset - cursor_offset).abs
        word_list.add_word(word, distance)
      end
      return word_list
    end
    
    def complete_word
      prefix, prefix_offsets = @cursor_state.context.touched_word
      if prefix
        @completion_state.esc_pressed(prefix, prefix_offsets)
      end
    end
    
    # sets the flag that a completion is occurring, this is because the "changed" signal is fired when text is replaced.
    def flag_completion
      @completion_flagged = !@completion_flagged
    end
  end
end
