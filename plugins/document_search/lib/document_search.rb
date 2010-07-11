
module DocumentSearch

  class SearchSpeedbar < Redcar::Speedbar
    class << self
      attr_accessor :previous_query
      attr_accessor :previous_is_regex
      attr_accessor :previous_match_case
    end
  
    def initial_query=(text)
      SearchSpeedbar.previous_query = text
    end

    def after_draw
      self.query.value = SearchSpeedbar.previous_query || ""
      self.is_regex.value = SearchSpeedbar.previous_is_regex
      self.match_case.value = SearchSpeedbar.previous_match_case
      self.query.edit_view.document.select_all
    end
    
    label :label, "Search:"
    textbox :query        
    
    toggle :is_regex, 'Regex', nil, false do |v|
      # v is true or false
      SearchSpeedbar.previous_is_regex = v          
    end
    
    toggle :match_case, 'Match case', nil, false do |v|
      SearchSpeedbar.previous_match_case = v          
    end      
    
    button :search, "Search", "Return" do
      SearchSpeedbar.previous_query = query.value
      SearchSpeedbar.previous_match_case = match_case.value
      SearchSpeedbar.previous_is_regex = is_regex.value
      success = SearchSpeedbar.repeat_query
    end
    
    def self.repeat_query
      current_query = @previous_query
      if !@previous_is_regex
        current_query = Regexp.escape(current_query)
      end
      FindNextRegex.new(Regexp.new(current_query, !@previous_match_case), true).run
    end
  end
    
  class SearchForwardCommand < Redcar::EditTabCommand
    
    def execute
      @speedbar = SearchSpeedbar.new
      if doc.selection?
        @speedbar.initial_query = doc.selected_text
      end
      win.open_speedbar(@speedbar)
    end
  end
  
  class RepeatPreviousSearchForwardCommand < Redcar::EditTabCommand
    def execute
      SearchSpeedbar.repeat_query
    end
  end
  
  class FindNextRegex < Redcar::EditTabCommand
    def initialize(re, wrap=nil)
      @re = re
      @wrap = wrap
    end
    
    def to_s
      "<#{self.class}: @re:#{@re.inspect} wrap:#{!!@wrap}>"
    end
    
    def execute
      # first search the remainder of the current line
      curr_line = doc.get_line(doc.cursor_line)
      cursor_line_offset = doc.cursor_offset - doc.offset_at_line(doc.cursor_line)
      curr_line = curr_line[cursor_line_offset..-1]
      if curr_line =~ @re
        line_start = doc.offset_at_line(doc.cursor_line)
        startoff = line_start + $`.length + cursor_line_offset
        endoff   = startoff + $&.length
        doc.set_selection_range(endoff, startoff)
      elsif doc.cursor_line < doc.line_count - 1
        # next search the rest of the lines
        found_line_offset = nil
        found_line_num = nil
        found_length = nil
        line_nums = ((doc.cursor_line() + 1)..(doc.line_count() - 1)).to_a # the rest of the document
        if @wrap
          line_nums += (0..doc.cursor_line()).to_a
        end
        for line_num in line_nums do
          curr_line = doc.get_line(line_num)
          if new_offset = (curr_line.to_s =~ @re)
            found_line_offset = new_offset
            found_line_num = line_num
            found_length = $&.length
            break
          end
        end
        if found_line_num
          line_start = doc.offset_at_line(found_line_num)
          startoff = line_start + found_line_offset
          endoff   = startoff + found_length
          doc.scroll_to_line(found_line_num)
          doc.set_selection_range(endoff, startoff)
          true
        else
          false
        end
      end
    end
  end
    
end
