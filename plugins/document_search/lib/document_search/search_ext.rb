
module DocumentSearch
	class SearchExtSpeedbar < Redcar::Speedbar
	  @@previous_query = ''
	  @@previous_replace = ''
	  @@previous_options = SearchExt::Options.new

	  attr_accessor :initial_query

    ### UI ###

		# Override num_columns to control number of rows.
		def num_columns
			return 7
		end

    label :label_search, "Search:"
    textbox :query

    combo :search_type, ["Regex", "Plain", "Glob"], "RegEx" do |val|
      @@previous_options.search_type = val
    end

		toggle :match_case, 'Match case', nil, false do |val|
		  @@previous_options.match_case = val
		end

		toggle :wrap_around, 'Wrap Around', nil, true do |val|
		  @@previous_options.wrap_around = val
		end

		label :label_spacer_end_row1a, ""
		label :label_spacer_end_row1b, ""
		label :label_spacer_start_row2, ""

    label :label_replace, "Replace:"
    textbox :replace

    button :replace_find, 'Replace && Find', "Return" do
      update_options_from_ui
      SearchExtSpeedbar.replace_and_find(@@previous_query, @@previous_replace, @@previous_options)
		end

    button :replace_all, "Replace All", nil do
			puts 'Replace All'
		end

		label :label_spacer_mid_row2, ""

		button :previous, "Previous", nil do
			puts 'Previous'
		end

		button :next, "Next", nil do
			update_options_from_ui
      SearchExtSpeedbar.search_next(@@previous_query, @@previous_options)
		end

		# Initializes UI elements.
		def after_draw
		  SearchSpeedbar.previous_query ||= ""
      self.query.value = @initial_query || SearchSpeedbar.previous_query || @@previous_query
      self.replace.value = @@previous_replace || ""
      self.search_type.value = SearchExtSpeedbar.search_type_to_text(@@previous_options.search_type)
      self.match_case.value = @@previous_options.match_case
      self.wrap_around.value = @@previous_options.wrap_around
      self.query.edit_view.document.select_all
		end  # after_draw

    # description here
    def update_options_from_ui
      @@previous_query = query.value
      @@previous_replace = replace.value
      @@previous_options.search_type = SearchExtSpeedbar.search_type_to_symbol(search_type.value)
      @@previous_options.match_case = match_case.value
      @@previous_options.wrap_around = wrap_around.value
    end  # update_options_from_ui


    ### UTILITY ###

    def self.search_type_to_symbol(search_type_text)
      case search_type_text
      when "Regex"
        :search_regex
      when "Plain"
        :search_plain
      when "Glob"
        :search_glob
      else
        puts "WARNING - Invalid search type: #{search_type_text} (defaulting to :search_regex)"
        :search_regex
      end
    end  # self.search_type_to_symbol

    def self.search_type_to_text(search_type_symbol)
      case search_type_symbol
      when :search_regex
        'Regex'
      when :search_plain
        'Plain'
      when :search_glob
        'Glob'
      else
        puts "WARNING - Invalid search type: #{search_type_symbol} (defaulting to 'Regex')"
        'Regex'
      end
    end  # self.search_type_to_text

    ### COMMANDS ###

    def self.search_next(query, options)
      cmd = SearchNextCommand.new(query, options)
      found_match = cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      if not found_match
        Redcar::Application::Dialog.message_box("The search string was not found.",
                                                {:type => :info, :buttons => :ok})
      end
    end  # self.search_next()

    # description here
    def self.replace_and_find(query, replace, options)
      cmd = ReplaceAndFindCommand.new(query, replace, options)
      found_match = cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      if not found_match
        Redcar::Application::Dialog.message_box("The search string was not found.",
                                                {:type => :info, :buttons => :ok})
      end
    end  # self.replace_and_find
	end  # class SearchExtSpeedbar
end  # module DocumentSearch
