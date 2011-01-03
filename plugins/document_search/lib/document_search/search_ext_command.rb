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
  		end
    end

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
      select_range(selection_pos, scanner.pos)
      true
    end

    def select_previous_match(doc, search_pos, query, wrap_around)
      previous_match = nil
      scanner = StringScanner.new(doc.get_all_text)
      scanner.pos = 0
      while scanner.scan_until(query)
        start_pos = scanner.pos - scanner.matched_size
        if start_pos < search_pos
          previous_match = [start_pos, scanner.pos]
        elsif previous_match
          select_range(*previous_match)
          return true
        elsif not wrap_around
          return false
        else
          break
        end
      end

      # Find the last match in the document.
      while scanner.scan_until(query)
        start_pos = scanner.pos - scanner.matched_size
        previous_match = [start_pos, scanner.pos]
      end

      if previous_match
        select_range(*previous_match)
        return true
      else
        return false
      end
    end

    def select_range(start, stop)
      doc.set_selection_range(start, stop)
      doc.scroll_to_line(doc.line_at_offset(start))
    end

    # description here
    def maybe_replace_selection(doc, start_pos, query, replace)
      scanner = StringScanner.new(doc.selected_text)
      scanner.check(query)
      if not scanner.matched?
        puts "WARNING - Failed to match query=#{query} for selection=#{doc.selected_text}"
        return 0
      elsif scanner.matched_size != doc.selected_text.length
        puts "WARNING - Failed to match query=#{query} for all of selection=#{doc.selected_text}"
        return 0
      end
      matched_text = doc.get_range(start_pos, scanner.matched_size)
      replacement_text = matched_text.gsub(query, replace)
      doc.replace(start_pos, scanner.matched_size, replacement_text)
      replacement_text.length
    end
  end


  class FindNextCommand < Redcar::DocumentCommand
    include SearchExt

    attr_reader :query

    # description here
    def initialize(query, options)
      @options = options
      @query = send(options.search_type, query, options)
    end

    # description here
    def execute
      offsets = [doc.cursor_offset, doc.selection_offset]
      start_pos = offsets.max
      if select_next_match(doc, start_pos, query, @options.wrap_around)
        true
      else
        # Clear selection as visual feedback that search failed.
        doc.set_selection_range(start_pos, start_pos)
        false
      end
    end
  end


  class FindPreviousCommand < Redcar::DocumentCommand
    include SearchExt

    attr_reader :query

    # description here
    def initialize(query, options)
      @options = options
      @query = send(options.search_type, query, options)
    end

    # description here
    def execute
      offsets = [doc.cursor_offset, doc.selection_offset]
      start_pos = offsets.min
      if select_previous_match(doc, start_pos, query, @options.wrap_around)
        true
      else
        # Clear selection as visual feedback that search failed.
        doc.set_selection_range(start_pos, start_pos)
        false
      end
    end
  end


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
    end

    def execute
      offsets = [doc.cursor_offset, doc.selection_offset]
      start_pos = offsets.min
      if doc.selected_text.length > 0
        chars_replaced = maybe_replace_selection(doc, start_pos, query, replace)
        if chars_replaced == 0
          start_pos = offsets.max
        else
          start_pos += chars_replaced
        end
      end
      if select_next_match(doc, start_pos, query, @options.wrap_around)
        true
      else
        # Clear selection as visual feedback that search failed.
        doc.set_selection_range(start_pos, start_pos)
        false
      end
    end
  end


  class ReplaceAllExtCommand < Redcar::DocumentCommand
    include SearchExt

    attr_reader :query, :replace

    # description here
    def initialize(query, replace, options)
      @options = options
      @query = send(options.search_type, query, options)
      @replace = replace
    end

    def execute
      startoff, endoff = nil
      text = doc.get_all_text
      count = 0
      sc = StringScanner.new(text)
      while sc.scan_until(query)
        count += 1

        startoff = sc.pos - sc.matched_size
        replacement_text = text.slice(startoff, sc.matched_size).gsub(query, replace)
        endoff = startoff + replacement_text.length

        text[startoff...sc.pos] = replacement_text
        sc.string = text
        sc.pos = startoff + replacement_text.length
      end
      if count > 0
        doc.text = text
        doc.set_selection_range(startoff + replacement_text.length, startoff)
        doc.scroll_to_line(doc.line_at_offset(startoff))
        true
      else
        false
      end
    end
  end
end