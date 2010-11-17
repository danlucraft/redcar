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
      score_match_pairs = []
      cutoff = 100000000
      results = list.each do |element|
        bit = block_given? ? yield(element) : element
        begin
          if m = bit.match(re)
            cs = []
            m.captures.each_with_index do |_, i|
              prev = cs.last
              if prev and m.begin(i + 1) == prev[0] - prev[1]
                cs.last[1] -= 1
              else
                cs << [m.begin(i + 1), m.begin(i + 1) - m.end(i + 1)]
              end
            end
            if cs.first.first < cutoff
              score_match_pairs << [cs, element]
              score_match_pairs = score_match_pairs.sort_by {|a| a.first }
              if score_match_pairs.length == max_length
                cutoff = score_match_pairs.last.first.first.first
                score_match_pairs.pop
              end
            end
          end
        rescue Errno::ENOENT
          # File.directory? can throw no such file or directory even if File.exist?
          # has returned true. For example this happens on some awful textmate filenames
          # unicode in them.
        end
      end
      score_match_pairs.map {|a| a.last }
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

