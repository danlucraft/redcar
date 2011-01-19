module Redcar
  module DocumentSearch
    # Utilities for extended search commands.
    module FindCommandMixin
      ### QUERY PATTERNS ###

      def is_valid(query)
        query.inspect != "//i"
      end

      # An instance of a search type method: Regular expression
      def query_regex(query, options)
        Regexp.new(query, !options.match_case)
      end

      # An instance of a search type method: Plain text search
      def query_plain(query, options)
        query_regex(Regexp.escape(query), options)
      end

      # An instance of a search type method: Glob text search
      # Converts a glob pattern (* or ?) into a regex pattern
      def query_glob(query, options)
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
        query_regex(new_query, options)
      end

      ### SELECTION ###

      # Selects the first match of query, starting from the start_pos.
      def select_next_match(doc, start_pos, query, wrap_around)
        return false unless is_valid(query)
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

      # Selects the match that first precedes the search position.
      #
      # The current implementation is brain-dead, but works: the document is scanned from the start
      # up to the search position, retaining the most recent match. Many smarter, but more
      # complicated strategies are possible; the best would be full reversal of the query regex, but
      # that obviously has a lot of tricky aspects to it.
      def select_previous_match(doc, search_pos, query, wrap_around)
        return false unless is_valid(query)
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

      # Replaces the current selection, if it matches the query completely.
      def replace_selection_if_match(doc, start_pos, query, replace)
        scanner = StringScanner.new(doc.selected_text)
        scanner.check(query)
        if (not scanner.matched?) || (scanner.matched_size != doc.selected_text.length)
          return 0
        end
        matched_text = doc.get_range(start_pos, scanner.matched_size)
        replacement_text = matched_text.gsub(query, replace)
        doc.replace(start_pos, scanner.matched_size, replacement_text)
        replacement_text.length
      end

      # Selects the specified range and scrolls to the start.
      def select_range(start, stop)
        line     = doc.line_at_offset(start)
        lineoff  = start - doc.offset_at_line(line)
        if lineoff < doc.smallest_visible_horizontal_index
          horiz = lineoff
        else
          horiz = stop - doc.offset_at_line(line)
        end
        doc.set_selection_range(start, stop)
        doc.scroll_to_line(line)
        doc.scroll_to_horizontal_offset(horiz) if horiz
      end
    end


    # Base class for find commands.
    class FindCommandBase < Redcar::DocumentCommand
      include FindCommandMixin

      attr_reader :query

      # description here
      def initialize(query, options)
        @options = options
        @query = send(options.query_type, query, options)
      end
    end


    # Finds the next match after the current location.
    class FindIncrementalCommand < FindCommandBase
      def execute
        offsets = [doc.cursor_offset, doc.selection_offset]
        start_pos = offsets.min
        if select_next_match(doc, start_pos, query, @options.wrap_around)
          true
        else
          # Clear selection as visual feedback that search failed.
          doc.set_selection_range(start_pos, start_pos)
          false
        end
      end
    end


    # Finds the next match after the current location.
    class FindNextCommand < FindCommandBase
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


    # Finds the previous match before the current location.
    class FindPreviousCommand < FindCommandBase
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


    # Base class for replace commands.
    class ReplaceCommandBase < Redcar::DocumentCommand
      include FindCommandMixin

      attr_reader :query, :replace

      # description here
      def initialize(query, replace, options)
        @options = options
        @query = send(options.query_type, query, options)
        @replace = replace
      end
    end


    # Replaces the currently selected text, if it matches the search criteria, then finds and
    # selects the next match in the document.
    #
    # This command maintains the invariant that no text is replaced without first being selected, so
    # the user always knows exactly what change is about to be made. A ramification of this policy
    # is that, if no text is selected beforehand, or the selected text does not match the query,
    # then "replace" portion of "replace and find" is essentially skipped, so that two button
    # presses are required.
    class ReplaceAndFindCommand < ReplaceCommandBase
      def execute
        offsets = [doc.cursor_offset, doc.selection_offset]
        start_pos = offsets.min
        if doc.selected_text.length > 0
          chars_replaced = replace_selection_if_match(doc, start_pos, query, replace)
          if chars_replaced > 0
            start_pos += chars_replaced
          else
            start_pos = offsets.max
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


    # Replaces all query matches.
    class ReplaceAllCommand < ReplaceCommandBase
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
          select_range(startoff + replacement_text.length, startoff)
          true
        else
          false
        end
      end
    end
  end
end