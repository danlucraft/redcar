module Redcar
  module DocumentSearch
    class FindSpeedbar < Redcar::Speedbar
      class << self
        attr_accessor :previous_query, :previous_replace, :previous_options
      end
      @previous_query = ''
      @previous_replace = ''
      @previous_options = QueryOptions.new

      attr_accessor :initial_query

      NotFoundMessage = 'Not found!'

      ### UI DEFINITION ###

      # Override num_columns to control number of rows.
      def num_columns
        return 7
      end

      label :label_find, 'Find:'
      textbox :query do |val|
        FindSpeedbar.previous_query = val
      end

      toggle :is_regex, 'Regex', nil, false do |val|
        FindSpeedbar.previous_options.is_regex = val
      end

      toggle :match_case, 'Match case', nil, false do |val|
        FindSpeedbar.previous_options.match_case = val
      end

      toggle :wrap_around, 'Wrap around', nil, true do |val|
        FindSpeedbar.previous_options.wrap_around = val
      end

      label :label_not_found, NotFoundMessage   # Hack: Set label for sizing, clear in after_draw
      label :label_space_end_row1, ""
      label :label_spacer_start_row2, ""

      label :label_replace, 'Replace:'
      textbox :replace do |val|
        FindSpeedbar.previous_replace = val
      end

      button :replace_find, 'Replace && Find', 'Alt+Return' do
        FindSpeedbar.replace_and_find(
            FindSpeedbar.previous_query,
            FindSpeedbar.previous_replace,
            FindSpeedbar.previous_options) or not_found
      end

      button :replace_all, 'Replace All', nil do
        FindSpeedbar.replace_all(
            FindSpeedbar.previous_query,
            FindSpeedbar.previous_replace,
            FindSpeedbar.previous_options) or not_found
      end

      button :replace_all_in_selection, 'Replace in Selection', nil do
        FindSpeedbar.replace_all_in_selection(
            FindSpeedbar.previous_query,
            FindSpeedbar.previous_replace,
            FindSpeedbar.previous_options) or not_found
      end

      button :find_previous, 'Previous', 'Shift+Return' do
        FindSpeedbar.find_previous or not_found
      end

      button :find_next, 'Next', 'Return' do
        FindSpeedbar.find_next or not_found
      end

      ### UI OPERATIONS ###

      # Initializes UI elements.
      def after_draw
        clear_not_found
        # If the current selection (from @initial_query) is equal to previous_replace, we ignore
        # that selection and just use the previous value for the query.
        #
        # This is especially important in the following command sequence: Select; Use selection for
        # query; Select; Use selection for replace; Open Find speedbar. Without the fix, the prior
        # selection for the query gets overwritten with the current selection, which is annoying and
        # useless.
        if ((FindSpeedbar.previous_replace.length > 0) &&
            (@initial_query == FindSpeedbar.previous_replace))
          self.query.value = FindSpeedbar.previous_query
        else
          if (@initial_query)
            FindSpeedbar.previous_query = @initial_query
          end
          self.query.value = FindSpeedbar.previous_query
        end
        self.replace.value = FindSpeedbar.previous_replace || ""
        self.is_regex.value = FindSpeedbar.previous_options.is_regex
        self.match_case.value = FindSpeedbar.previous_options.match_case
        self.wrap_around.value = FindSpeedbar.previous_options.wrap_around
        self.query.edit_view.document.select_all
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
        if active_speedbar && (active_speedbar.is_a? FindSpeedbar)
          active_speedbar.query.value = FindSpeedbar.previous_query
        end
      end

      def self.replace_and_find(query, replace, options)
        cmd = ReplaceAndFindCommand.new(query, replace, options)
        cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      end

      def self.replace_all(query, replace, options)
        cmd = ReplaceAllCommand.new(query, replace, options, false)
        cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      end

      def self.replace_all_in_selection(query, replace, options)
        cmd = ReplaceAllCommand.new(query, replace, options, true)
        cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      end

      def self.use_selection_for_replace(doc, active_speedbar=nil)
        return unless doc.selection?
        FindSpeedbar.previous_replace = doc.selected_text
        if active_speedbar && (active_speedbar.instance_of? FindSpeedbar)
          active_speedbar.replace.value = FindSpeedbar.previous_replace
        end
      end
    end
  end
end
