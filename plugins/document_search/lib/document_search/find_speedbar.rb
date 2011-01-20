module Redcar
  module DocumentSearch
    class FindSpeedbar < Redcar::Speedbar
      class << self
        attr_accessor :previous_query, :previous_options
      end
      @previous_query = ''
      @previous_options = QueryOptions.new

      attr_accessor :initial_query

      def doc
        win = Redcar.app.focussed_window
        tab = win.focussed_notebook_tab
        tab.document if tab
      end

      def after_draw
        FindSpeedbar.previous_query ||= ""
        self.query.value = @initial_query || FindSpeedbar.previous_query
        self.query_type.value = QueryOptions.query_type_to_text(
            FindSpeedbar.previous_options.query_type)
        self.match_case.value = FindSpeedbar.previous_options.match_case
        self.wrap_around.value = FindSpeedbar.previous_options.wrap_around
        self.query.edit_view.document.select_all
      end

      label :label, "Find:"
      textbox :query do |value|
        if doc
          update_options_from_ui
          FindSpeedbar.find_incremental
        end
      end

      combo :query_type, ["Plain", "Regex", "Glob"], "Plain" do |val|
        FindSpeedbar.previous_options.query_type = QueryOptions.query_type_to_symbol(val)
        update_options_from_ui
        FindSpeedbar.find_incremental
      end

      toggle :match_case, 'Match case', nil, false do |val|
        FindSpeedbar.previous_options.match_case = val
        update_options_from_ui
        FindSpeedbar.find_incremental
      end

      toggle :wrap_around, 'Wrap around', nil, true do |val|
        FindSpeedbar.previous_options.wrap_around = val
        update_options_from_ui
        FindSpeedbar.find_incremental
      end

      button :previous, "Previous", "Alt+Return" do
        if doc
          update_options_from_ui
          FindSpeedbar.find_previous
        end
      end

      button :next, "Next", "Return" do
        if doc
          update_options_from_ui
          FindSpeedbar.find_next
        end
      end

      def update_options_from_ui
        if doc and self.query.value and self.query.value != ""
          FindSpeedbar.previous_query = self.query.value
          FindSpeedbar.previous_options.query_type =
              QueryOptions.query_type_to_symbol(self.query_type.value)
          FindSpeedbar.previous_options.match_case = self.match_case.value
          FindSpeedbar.previous_options.wrap_around = self.wrap_around.value
        end
      end

      def self.find_incremental
        cmd = FindIncrementalCommand.new(FindSpeedbar.previous_query, FindSpeedbar.previous_options)
        cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      end

      def self.find_next
        cmd = FindNextCommand.new(FindSpeedbar.previous_query, FindSpeedbar.previous_options)
        cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      end

      def self.find_previous
        cmd = FindPreviousCommand.new(FindSpeedbar.previous_query, FindSpeedbar.previous_options)
        cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      end

      # Note: The assumption that we set find only from selected text means we don't have to update
      # search.
      def self.use_selection_for_find(doc, active_speedbar=nil)
        return unless doc.selection?
        FindSpeedbar.previous_query = doc.selected_text
        if active_speedbar
          active_speedbar.query.value = FindSpeedbar.previous_query
        end
      end
    end
  end
end