module Redcar
  class AutoHighlighter
    class DocumentController

      attr_accessor :gc, :styledText, :document
      attr_accessor :height, :width, :highlighted
 
      include Redcar::Document::Controller
      include Redcar::Document::Controller::ModificationCallbacks
      include Redcar::Document::Controller::CursorCallbacks

      #def before_modify(start_offset, end_offset, text)
      #  puts "Call before!"
	#@wait = true
   #   end

    #  def after_modify
     #   puts "Call after!"
	#@wait = false
	#cursor_moved(styledText.getCaretOffset)
   #   end

 
      def initialize
        @i = 0
        @highlighted_current = nil
        @highlighted_pair = nil
        @open_pair_chars = ["{", "(", "["]
        @close_pair_chars = ["}", ")", "]"]
        @pair_chars = @open_pair_chars + @close_pair_chars
      end

      def highlight_pair(current, pair)
        
        if current == nil or pair == nil
          clear
          return
        elsif current == @highlighted_current || current == @highlighted_pair || pair == @highlighted_current || pair == @highlighted_pair
          return
        end

        #puts "Highligh on offset " + current.to_s() + " and its pair at " + pair.to_s()
        if document.length > 0
          clear
          #puts "Highligh on offset " + current.to_s() + " and its pair at " + pair.to_s()
          @pos_current = styledText.getLocationAtOffset(current)
          @pos_pair = styledText.getLocationAtOffset(pair)
          gc.background = ApplicationSWT.display.system_color Swt::SWT::COLOR_GRAY
          gc.setAlpha(98)
          rectangle1 = styledText.getTextBounds(current, current)
          rectangle2 = styledText.getTextBounds(pair, pair)
          gc.fill_rectangle(rectangle1)
          gc.fill_rectangle(rectangle2)          
          @highlighted_current = current
    	  @highlighted_pair = pair
	      @highlighted = true
        end
      end
      
      def clear
        if @highlighted
	        styledText.redrawRange(@highlighted_current, 1, false) if @highlighted_current < document.length
	        styledText.redrawRange(@highlighted_pair, 1, false) # if on the same line
          @highlighted_current = nil
          @highlighted_pair = nil
          @highlighted = false
        end
      end
      
      def find_pair(step, offset, search_char, current_char)
        if offset == 0
          return nil
        end
        state = 1;
        quotes = false
        doublequotes = false
        
        while offset > 0 and offset < document.length
          offset = offset + step;
          @newchar = styledText.getTextRange(offset, 1)
          if @newchar == search_char and !quotes and !doublequotes
            state = state - 1
          elsif @newchar == current_char and !quotes and !doublequotes
            state = state + 1
          elsif @newchar == '"'
            doublequotes = !doublequotes
          elsif @newchar == "'"
            quotes = !quotes
          end
          if state == 0
            return offset
          end
        end
        
        if state != 0
          return nil
        end
      end

      def pair_of_offset(offset)
        @char = document.get_range(offset, 1)
        @index = @open_pair_chars.index(@char)
        @newoffset = nil

        if @index
          @newoffset = find_pair(1, offset, @close_pair_chars[@index], @open_pair_chars[@index])
        else
          @index = @close_pair_chars.index(@char)
          if @index
            @newoffset = find_pair(-1, offset, @open_pair_chars[@index], @close_pair_chars[@index])
          end
        end
        return @newoffset
      end

      def cursor_moved(offset)
        
        if @wait
          return
        end
        
        pair = nil
        
        if offset >= document.length
            @char_next = nil
        else
            @char_next = document.get_range(offset, 1)    
        end
        
        if offset > 0
            @char_prev = document.get_range(offset-1, 1) 
        else
            @char_prev = nil
        end
        
        if @char_next and @pair_chars.include?(@char_next)
            pair = pair_of_offset(offset)            
        elsif @char_prev and @pair_chars.include?(@char_prev)
            offset = offset - 1
            pair = pair_of_offset(offset)
        else
            clear
        end
        
        highlight_pair(offset, pair)
        #puts "Highlight! " + @i.to_s
        #@i = @i + 1
      end
    end
  end
end
