module Redcar
  # A type of dialog containing a textbox and a list, where the list can be updated
  # based on the contents of the textbox. For example, the Find File dialog box in
  # the Project plugin.
  #
  # Subclasses should implement the 'update_list' method and the 'selected' method.
  class FilterListDialog
    include Redcar::Model
    include Redcar::Observable
  
    def initialize
      self.controller = Redcar.gui.controller_for(self).new(self)
    end
    
    def open
      notify_listeners(:open)
    end
    
    def close
      notify_listeners(:close)
    end
    
    # Called by the controller when the user changes the filter.
    #
    # @param [String] the filter entered by the user
    # @return [Array<String>] the new list to display
    def update_list(filter)
      if filter == ""
        %w(foo bar baz qux quux corge)
      else
        a = []
        5.times {|i| a << filter + " " + i.to_s }
        a
      end
    end
    
    # Called by the controller when the user selects a row in the list.
    #
    # @param [String] the list row text selected by the user
    # @param [Integer] the index of the row in the list selected by the user
    def selected(text, ix)
      puts "Hooray! You selected #{text} at index #{ix}"
    end
    
    # Called by the controller when the user moves through the list.
    #
    # @param [String] the list row text that is now highlighted
    # @param [Integer] the index of the row that is now highlighted
    def moved_to(text, ix)
      # Override with the code you wish you had
    end

    # Helper method for fuzzily filtering a list
    #
    # @param [Array<A>]     list        the list to filter
    # @param [String]       query       the fuzzy string to match on
    # @param [Integer]      max_length  the length of the resulting list (default 20)
    # @block A -> String    optionally turns an element from the list into a string to match on
    def filter_and_rank_by(list, query, max_length=20)
      re = make_regex(query)
      ranked_list = []
      cutoff = 100000000
      results = list.each do |element|
        begin
          match_data = (block_given? ? yield(element) : element).match(re)
          if match_data
            captures = []
            match_data.captures.each_with_index do |_, i|
              i += 1 # Match group 0 is actually the complete regex, we are interested in the subgroups
              previous_capture = captures.last
              if previous_capture and match_data.begin(i) - previous_capture[:end] <= 1
                # If the the current match starts where the previous match ended, or they even overlap, merge the matches
                captures.last[:end] = match_data.end(i)
              else
                # Record the match
                captures << {:begin => match_data.begin(i), :end => match_data.end(i)}
              end
            end
            if captures.first[:begin] < cutoff
              # The penalty is calculated as such: The values of the beginnings of matches are penalty, the lengths are bonuses
              # This way, matching early and continiously is rewarded. Matching late in a word or only at intervals is punished.
              penalty = captures.inject(0) {|p,c| p + c[:begin] - (c[:end] - c[:begin]) }
              ranked_list << {:penalty => penalty, :first_match => captures.first[:begin], :element => element}
              ranked_list = ranked_list.sort_by {|a| a[:penalty] }

              # Performance optimization: Once we reach the maximum length, remove elements (saves later sorting)
              # Set the new cutoff to the beginning of the previously last element, to avoid later elements getting
              # into the list which would have an even worse rank.
              if ranked_list.length > max_length
                cutoff = ranked_list.last[:first_match]
                ranked_list.pop
              end
            end
          end
        rescue Errno::ENOENT
          # File.directory? can throw no such file or directory even if File.exist?
          # has returned true. For example this happens on some awful textmate filenames
          # unicode in them.
        end
      end
      ranked_list.map {|a| a[:element] }
    end
    
    # The time interval in seconds in which moved_to events are ignored
    # Override to select different interval
    def step_time
      1
    end

    def step?
      @last_step ||= Time.now - step_time
      @last_step + step_time <= Time.now
    end

    private
    
    def make_regex(text)
      re_src = "(" + text.split(//).map{|l| Regexp.escape(l) }.join(").*?(") + ")"
      Regexp.new(re_src, :options => Regexp::IGNORECASE)
    end
  end
end

