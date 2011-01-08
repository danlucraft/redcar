module DocumentSearch
  class FindAndReplaceSpeedbar < Redcar::Speedbar
    NotFoundMessage = 'Not found!'

    @@previous_query = ''
    @@previous_replace = ''
    @@previous_options = SearchOptions.new

    attr_accessor :initial_query

    ### UI ###

    # Override num_columns to control number of rows.
    def num_columns
      return 7
    end

    label :label_find, "Find:"
    textbox :query

    combo :search_type, ["Plain", "Regex", "Glob"], "Plain" do |val|
      @@previous_options.search_type = val
    end

    toggle :match_case, 'Match case', nil, false do |val|
      @@previous_options.match_case = val
    end

    toggle :wrap_around, 'Wrap Around', nil, true do |val|
      @@previous_options.wrap_around = val
    end

    label :label_not_found, NotFoundMessage   # Hack: Set label for sizing, clear in after_draw
    label :label_space_end_row1, ""
    label :label_spacer_start_row2, ""

    label :label_replace, "Replace:"
    textbox :replace

    button :replace_find, 'Replace && Find', "Return" do
      update_options_from_ui
      FindAndReplaceSpeedbar.replace_and_find(
          @@previous_query, @@previous_replace, @@previous_options) or not_found
    end

    button :replace_all, "Replace All", nil do
      update_options_from_ui
      FindAndReplaceSpeedbar.replace_all(
          @@previous_query, @@previous_replace, @@previous_options) or not_found
    end

    label :label_spacer_mid_row2, ""

    button :find_previous, "Previous", nil do
      update_options_from_ui
      FindAndReplaceSpeedbar.find_previous(@@previous_query, @@previous_options) or not_found
    end

    button :find_next, "Next", nil do
      update_options_from_ui
      FindAndReplaceSpeedbar.find_next(@@previous_query, @@previous_options) or not_found
    end

    # Initializes UI elements.
    def after_draw
      clear_not_found
      self.query.value = @initial_query || @@previous_query
      self.replace.value = @@previous_replace || ""
      self.search_type.value = SearchOptions.search_type_to_text(@@previous_options.search_type)
      self.match_case.value = @@previous_options.match_case
      self.wrap_around.value = @@previous_options.wrap_around
      self.query.edit_view.document.select_all
    end

    # Store options specified in the UI, to be called before executing a command.
    def update_options_from_ui
      clear_not_found
      @@previous_query = query.value
      @@previous_replace = replace.value
      @@previous_options.search_type = SearchOptions.search_type_to_symbol(search_type.value)
      @@previous_options.match_case = match_case.value
      @@previous_options.wrap_around = wrap_around.value
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

    def self.find_previous(query, options)
      cmd = FindPreviousCommand.new(query, options)
      cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
    end

    def self.find_next(query, options)
      cmd = FindNextCommand.new(query, options)
      cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
    end

    def self.repeat_find_next
      find_next(@@previous_query, @@previous_options) or not_found
    end

    def self.repeat_find_previous
      find_previous(@@previous_query, @@previous_options) or not_found
    end

    # description here
    def self.replace_and_find(query, replace, options)
      cmd = ReplaceAndFindCommand.new(query, replace, options)
      cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
    end

    def self.replace_all(query, replace, options)
      cmd = ReplaceAllCommand.new(query, replace, options)
      cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
    end
  end
end
