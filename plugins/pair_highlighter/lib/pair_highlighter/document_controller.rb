
module Redcar
  class PairHighlighter
    class DocumentController

      attr_accessor :gc, :styledText, :document, :mate_text, :theme_name
      attr_accessor :height, :width, :highlighted

      include Redcar::Document::Controller
      include Redcar::Document::Controller::ModificationCallbacks
      include Redcar::Document::Controller::CursorCallbacks

      def set_highlight_colour
        if @theme_name == EditView.theme
          return @colour if @colour
        end

        @theme_name = EditView.theme
        @theme = @mate_text.colourer.getTheme()
        @colour = @theme.globalSettings.get("pairHighlight")
      	if @colour
      	  @colour = JavaMateView::SwtColourer.getColour(@colour)
      	else
          @colour = ApplicationSWT.display.system_color Swt::SWT::COLOR_GRAY
      	end
      	@colour
      end

      def before_modify(start_offset, end_offset, text)
        @wait = @wait + 1
      end

      def after_modify
        @wait = @wait - 1
	    end

      def initialize
        @i = 0
        @wait = 0
        @theme_name = nil
        @highlight = Highlighted.new
        @open_pair_chars = ["{", "(", "["]
        @close_pair_chars = ["}", ")", "]"]
        @pair_chars = @open_pair_chars + @close_pair_chars
      end

      def highlight_pair(current, pair)
        if current == nil or pair == nil
          clear
          return
        elsif current == @highlight.current || current == @highlight.pair || pair == @highlight.current || pair == @highlight.pair
          return
        end

        #puts "Highligh on offset " + current.to_s() + " and its pair at " + pair.to_s()
        if document.length > 0
          clear
          #puts "Highligh on offset " + current.to_s() + " and its pair at " + pair.to_s()
          gc = Swt::Graphics::GC.new(@styledText)
          gc.setBackground(set_highlight_colour)
          gc.setAlpha(98)
          gc.fill_rectangle(styledText.getTextBounds(current, current))
          gc.fill_rectangle(styledText.getTextBounds(pair, pair))
          @highlight.set_on(current, pair)
          gc.dispose() if gc
        end
      end

      def clear
        if @highlight.on?
          if @highlight.current < document.length
            styledText.redrawRange(@highlight.current, 1, false)
            styledText.redrawRange(@highlight.pair, 1, false) # if on the same line
            @highlight.clear
          end
        end
      end

      def find_pair(step, offset, search_char, current_char)
        state = 1;
        quotes = false
        doublequotes = false

        offset = offset + step;
        while offset >= 0 and offset < document.length
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
          offset = offset + step;
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
        if @wait > 0
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
      end
    end

    class Highlighted
      attr_accessor :on, :current, :pair

      def initialize
        clear
      end

      def clear
        @on = false
        @current = nil
        @pair = nil
      end

      def on?
        if @on
          true
        else
          false
        end
      end

      def set_on(current, pair)
        if current and pair
          @on = true
          @current = current
          @pair = pair
        end
      end
    end
  end
end
