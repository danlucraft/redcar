module DocumentSearch
  module SearchExt
    class Options
      attr_accessor :search_type
  		attr_accessor :match_case
  		attr_accessor :wrap_around

  		# Initializes with default options.
  		def initialize
  		  @search_type = :search_regex
  		  @match_case = false
  		  @wrap_around = true
  		end  # initialize
    end  # class Options

    ### SEARCH PATTERNS ###

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

    # description here
    def select_next_match(doc, start_pos, query, wrap_around)
      scanner = StringScanner.new(doc.get_all_text)
      scanner.pos = start_pos
      if not scanner.scan_until(query)
        if not wrap_around
          return false
        end

        scanner.reset
        if not scanner.scan_until(query)
          return false
        end
      end

      selection_pos = scanner.pos - scanner.matched_size
      doc.set_selection_range(selection_pos, scanner.pos)
      doc.scroll_to_line(doc.line_at_offset(selection_pos))
      true
    end  # select_next_match()
  end  # module SearchExt


  class SearchNextCommand < Redcar::DocumentCommand

  end  # class SearchNextCommand

  # Replaces the currently selected text, if it matches the search criteria, then finds and selects
  # the next match in the document.
  #
  # This command maintains the invariant no text is replaced without first being selected, so that
  # the user always knows exactly what change is about to be made. A ramification of this policy is
  # that, if not text is selected beforehand, or the selected text does not match the query, then
  # "replace" portion of "replace and find" is essentially skipped, so that two button presses are
  # required.
  class ReplaceAndFindCommand < Redcar::DocumentCommand
    include SearchExt

    attr_reader :query, :replace

    # description here
    def initialize(query, replace, options)
      @options = options
      @query = send(options.search_type, query, options)
      @replace = replace
    end  # initialize()

    def execute
      # Check if the selection matches.
      offsets = [doc.cursor_offset, doc.selection_offset]
     # scanner = StringScanner.new(doc.get_all_text)
      #scanner.pos = offsets.min
      start_pos = offsets.min
      if query === doc.selected_text
        chars_replaced = ReplaceAndFindCommand.replace_selection(doc, start_pos, query, replace)
        start_pos += chars_replaced
      end
      if select_next_match(doc, start_pos, query, @options.wrap_around)
        true
      else
        # Clear selection as visual feedback that search failed.
        doc.set_selection_range(start_pos, start_pos)
        false
      end
    end  # execute

    # description here
    def self.replace_selection(doc, start_pos, query, replace)
      scanner = StringScanner.new(doc.selected_text)
      scanner.check(query)
      if not scanner.matched?
        raise "Failed to match query=#{query} for selection=#{doc.selected_text}"
      elsif scanner.matched_size != doc.selected_text.length
        raise "Failed to match query=#{query} for all of selection=#{doc.selected_text}"
      end
      matched_text = doc.get_range(start_pos, scanner.matched_size)
      replacement_text = matched_text.gsub(query, replace)
      doc.replace(start_pos, scanner.matched_size, replacement_text)
      replacement_text.length
    end  # self.replace_selection()
  end  # class ReplaceAndFindCommand
end  # module DocumentSearch