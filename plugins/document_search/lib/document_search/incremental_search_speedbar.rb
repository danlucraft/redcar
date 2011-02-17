module Redcar
  module DocumentSearch
    class IncrementalSearchSpeedbar < Redcar::Speedbar
      class << self
        attr_accessor :previous_query, :previous_options
      end
      @previous_query = ''
      @previous_options = QueryOptions.new

      ### UI ###

      label :label, 'Find:'
      textbox :query do |value|
        # Check to avoid multiple searches from duplicate text update events.
        if IncrementalSearchSpeedbar.previous_query != self.query.value
          IncrementalSearchSpeedbar.previous_query = self.query.value
          IncrementalSearchSpeedbar.find_incremental
        end
      end

      toggle :is_regex, 'Regex', nil, false do |val|
        IncrementalSearchSpeedbar.previous_options.is_regex = val
        IncrementalSearchSpeedbar.find_incremental
      end

      toggle :match_case, 'Match case', nil, false do |val|
        IncrementalSearchSpeedbar.previous_options.match_case = val
        IncrementalSearchSpeedbar.find_incremental
      end

      toggle :wrap_around, 'Wrap around', nil, true do |val|
        IncrementalSearchSpeedbar.previous_options.wrap_around = val
        IncrementalSearchSpeedbar.find_incremental
      end

      def after_draw
        IncrementalSearchSpeedbar.previous_query ||= ""
        self.query.value = IncrementalSearchSpeedbar.previous_query
        self.is_regex.value = IncrementalSearchSpeedbar.previous_options.is_regex
        self.match_case.value = IncrementalSearchSpeedbar.previous_options.match_case
        self.wrap_around.value = IncrementalSearchSpeedbar.previous_options.wrap_around
        self.query.edit_view.document.select_all
      end

      ### COMMANDS ###

      def self.find_incremental
        cmd = FindNextCommand.new(
            IncrementalSearchSpeedbar.previous_query,
            IncrementalSearchSpeedbar.previous_options,
            always_start_within_selection=true)
        cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      end

      def self.find_next
        cmd = FindNextCommand.new(
            IncrementalSearchSpeedbar.previous_query,
            IncrementalSearchSpeedbar.previous_options)
        cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      end

      def self.find_previous
        cmd = FindPreviousCommand.new(
            IncrementalSearchSpeedbar.previous_query,
            IncrementalSearchSpeedbar.previous_options)
        cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      end
    end
  end
end