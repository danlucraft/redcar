
module Redcar
  module DocumentSearch
    class FindAndReplaceSpeedbar < Redcar::Speedbar
      NotFoundMessage = 'Not found!'

      class << self
        attr_accessor :previous_replace
      end
      @@previous_replace = ''

      attr_accessor :initial_query

      def doc
        win = Redcar.app.focussed_window
        tab = win.focussed_notebook_tab
        tab.document if tab
      end

      ### UI ###

      # Override num_columns to control number of rows.
      def num_columns
        return 7
      end

      label :label_find, "Find:"
      textbox :query do
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

      label :label_not_found, NotFoundMessage   # Hack: Set label for sizing, clear in after_draw
      label :label_space_end_row1, ""
      label :label_spacer_start_row2, ""

      label :label_replace, "Replace:"
      textbox :replace

      button :replace_find, 'Replace && Find', "Return" do
        update_options_from_ui
        FindAndReplaceSpeedbar.replace_and_find(
        FindSpeedbar.previous_query, FindAndReplaceSpeedbar.previous_replace, FindSpeedbar.previous_options) or not_found
      end

      button :replace_all, "Replace All", nil do
        update_options_from_ui
        FindAndReplaceSpeedbar.replace_all(
        FindSpeedbar.previous_query, FindAndReplaceSpeedbar.previous_replace, FindSpeedbar.previous_options) or not_found
      end

      label :label_spacer_mid_row2, ""

      button :find_previous, "Previous", nil do
        update_options_from_ui
        FindSpeedbar.find_previous or not_found
      end

      button :find_next, "Next", nil do
        update_options_from_ui
        FindSpeedbar.find_next or not_found
      end

      # Initializes UI elements.
      def after_draw
        clear_not_found
        self.query.value = @initial_query || FindSpeedbar.previous_query
        self.replace.value = FindAndReplaceSpeedbar.previous_replace || ""
        self.query_type.value = QueryOptions.query_type_to_text(FindSpeedbar.previous_options.query_type)
        self.match_case.value = FindSpeedbar.previous_options.match_case
        self.wrap_around.value = FindSpeedbar.previous_options.wrap_around
        self.query.edit_view.document.select_all
      end

      # Store options specified in the UI, to be called before executing a command.
      def update_options_from_ui
        clear_not_found
        FindSpeedbar.previous_query = query.value
        FindAndReplaceSpeedbar.previous_replace = replace.value
        FindSpeedbar.previous_options.query_type = QueryOptions.query_type_to_symbol(query_type.value)
        FindSpeedbar.previous_options.match_case = match_case.value
        FindSpeedbar.previous_options.wrap_around = wrap_around.value
      end

      # Sets the "Not found" label message, invoking the system beep.
      def not_found
        Swt::Widgets::Display.get_current.beep
        self.label_not_found.text = NotFoundMessage
      end

      # Clears the "Not found" label message.
      def clear_not_found
        self.label_not_found.text = ''
      end

      ### COMMANDS ###

      def self.repeat_find_next
        find_next(FindSpeedbar.previous_query, FindSpeedbar.previous_options) or not_found
      end

      def self.repeat_find_previous
        find_previous(FindSpeedbar.previous_query, FindSpeedbar.previous_options) or not_found
      end

      def self.replace_and_find(query, replace, options)
        cmd = ReplaceAndFindCommand.new(query, replace, options)
        cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      end

      def self.replace_all(query, replace, options)
        cmd = ReplaceAllCommand.new(query, replace, options)
        cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      end

      def self.use_selection_for_replace(doc, active_speedbar=nil)
        return unless doc.selection?
        FindAndReplaceSpeedbar.previous_replace = doc.selected_text
        if active_speedbar && (active_speedbar.instance_of? FindAndReplaceSpeedbar)
          active_speedbar.replace.value = FindAndReplaceSpeedbar.previous_replace
        end
      end
    end
  end
end