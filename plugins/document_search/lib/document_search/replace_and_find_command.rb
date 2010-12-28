module DocumentSearch
  # Replaces the currently selected text, if it matches the search criteria, then finds and selects
  # the next match in the document.
  #
  # This command maintains the invariant no text is replaced without first being selected, so that
  # the user always knows exactly what change is about to be made. A ramification of this policy is
  # that, if not text is selected beforehand, or the selected text does not match the query, then
  # "replace" portion of "replace and find" is essentially skipped, so that two button presses are
  # required.
  class ReplaceAndFindCommand < Redcar::DocumentCommand
    attr_reader :query, :replace

    class Options
	    attr_accessor :query
      attr_accessor :replace
      attr_accessor :search_type
			attr_accessor :match_case
			attr_accessor :wrap_around

			# Initializes with default options.
			def initialize
			  @query = ''
			  @replace = ''
			  @search_type = :search_regex
			  @match_case = false
			  @wrap_around = true
			end  # initialize
    end  # class Options

    # description here
    def initialize(options)
      @options = options
      @query = send(options.search_type, options.query, options)
      @replace = options.replace
    end  # initialize()


    ### SEARCH ###

    # An instance of a search type method: Regular expression
    def search_regex(query, options)
      Regexp.new(query, !options.match_case)
    end

    # An instance of a search type method: Plain text search
    def search_plain(query, options)
      search_regex(Regexp.escape(query), options)
    end

    # An instance of a search type method: Glob text search
    # Converts a glob pattern (* or ?) into a regex pattern
    def search_glob(query, options)
      # convert the glob pattern to a regex pattern
      new_query = ""
      query.each_char do |c|
        case c
        when "*"
          new_query << ".*"
        when "?"
          new_query << "."
        else
          new_query << Regexp.escape(c)
        end
      end
      search_regex(new_query, options)
    end

    # def first_match_position
    #   offsets = [doc.cursor_offset, doc.selection_offset]
    #   puts "in start_position: offsets = #{offsets.join(',')}"
    #   if query === doc.selected_text then
    #     return offsets.min
    #   else
    #     return -1
    #   end
    # end

    def execute
      # Check if the selection matches.
      offsets = [doc.cursor_offset, doc.selection_offset]
     # scanner = StringScanner.new(doc.get_all_text)
      #scanner.pos = offsets.min
      start_pos = offsets.min
      puts "before start_pos = #{start_pos}"
      if query === doc.selected_text then
        chars_replaced = ReplaceAndFindCommand.replace_selection(doc, start_pos, query, replace)
        start_pos += chars_replaced
      end
      puts "after start_pos = #{start_pos}"
      if ReplaceAndFindCommand.select_next_match(doc, start_pos, query, @options.wrap_around) then
        true
      else
        # Clear selection as visual feedback that search failed.
        doc.set_selection_range(start_pos, start_pos)
        false
      end
    end

    # description here
    def self.replace_selection(doc, start_pos, query, replace)
      scanner = StringScanner.new(doc.selected_text)
      scanner.check(query)
      if not scanner.matched? then
        raise "Failed to match query=#{query} for selection=#{doc.selected_text}"
      elsif scanner.matched_size != doc.selected_text.length then
        raise "Failed to match query=#{query} for all of selection=#{doc.selected_text}"
      end
      puts "Matched query=#{query} at selection=#{doc.selected_text}"

      matched_text = doc.get_range(start_pos, scanner.matched_size)
      replacement_text = matched_text.gsub(query, replace)
      doc.replace(start_pos, scanner.matched_size, replacement_text)
      replacement_text.length
    end  # self.replace_selection()

    # description here
    def self.select_next_match(doc, start_pos, query, wrap_around)
      scanner = StringScanner.new(doc.get_all_text)
      scanner.pos = start_pos
      if not scanner.scan_until(query) then
        if not wrap_around then
          return false
        end

        scanner.reset
        if not scanner.scan_until(query) then
          return false
        end
      end

      selection_pos = scanner.pos - scanner.matched_size
      doc.set_selection_range(selection_pos, scanner.pos)
      doc.scroll_to_line(doc.line_at_offset(selection_pos))
      true
    end  # select_next_match()
  end
end