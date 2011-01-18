module DocumentSearch
  class IncrementalSearchSpeedbar < Redcar::Speedbar
    @@previous_query = ''
    @@previous_options = QueryOptions.new
    class << self
      attr_accessor :previous_query, :previous_options
    end

    attr_accessor :initial_query

    def doc
      win = Redcar.app.focussed_window
      tab = win.focussed_notebook_tab
      tab.document if tab
    end

    def after_draw
      IncrementalSearchSpeedbar.previous_query ||= ""
      self.query.value = @initial_query || IncrementalSearchSpeedbar.previous_query
      self.query_type.value = QueryOptions.query_type_to_text(
          IncrementalSearchSpeedbar.previous_options.query_type)
      self.match_case.value = IncrementalSearchSpeedbar.previous_options.match_case
      self.wrap_around.value = IncrementalSearchSpeedbar.previous_options.wrap_around
      self.query.edit_view.document.select_all
    end

    label :label, "Find:"
    textbox :query do |value|
      if doc
        update_options_from_ui
        IncrementalSearchSpeedbar.find_incremental
      end
    end

    combo :query_type, ["Plain", "Regex", "Glob"], "Plain" do |val|
      IncrementalSearchSpeedbar.previous_options.query_type = QueryOptions.query_type_to_symbol(val)
      update_options_from_ui
      IncrementalSearchSpeedbar.find_incremental
    end

    toggle :match_case, 'Match case', nil, false do |val|
      IncrementalSearchSpeedbar.previous_options.match_case = val
      update_options_from_ui
      IncrementalSearchSpeedbar.find_incremental
    end

    toggle :wrap_around, 'Wrap around', nil, true do |val|
      IncrementalSearchSpeedbar.previous_options.wrap_around = val
      update_options_from_ui
      IncrementalSearchSpeedbar.find_incremental
    end

    button :previous, "Previous", "Alt+Return" do
      if doc
        update_options_from_ui
        IncrementalSearchSpeedbar.find_previous
      end
    end

    button :next, "Next", "Return" do
      if doc
        update_options_from_ui
        IncrementalSearchSpeedbar.find_next
      end
    end

    def update_options_from_ui
      if doc and self.query.value and self.query.value != ""
        IncrementalSearchSpeedbar.previous_query = self.query.value
        IncrementalSearchSpeedbar.previous_options.query_type =
            QueryOptions.query_type_to_symbol(self.query_type.value)
        IncrementalSearchSpeedbar.previous_options.match_case = self.match_case.value
        IncrementalSearchSpeedbar.previous_options.wrap_around = self.wrap_around.value
      end
    end

    def self.find_incremental
      cmd = FindIncrementalCommand.new(
          IncrementalSearchSpeedbar.previous_query,
          IncrementalSearchSpeedbar.previous_options)
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

    # Note: The assumption that we set find only from selected text means we don't have to update
    # search.
    def self.use_selection_for_find(doc, active_speedbar=nil)
      return unless doc.selection?
      IncrementalSearchSpeedbar.previous_query = doc.selected_text
      if active_speedbar
        active_speedbar.query.value = IncrementalSearchSpeedbar.previous_query
      end
    end
  end
end