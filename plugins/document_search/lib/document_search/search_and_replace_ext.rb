
module DocumentSearch
	class SearchAndReplaceExtSpeedbar < Redcar::Speedbar
	  @@options_cache = ReplaceAndFindCommand::Options.new

    class << self
      attr_accessor :previous_query
      attr_accessor :previous_replace
      attr_accessor :previous_search_type
			attr_accessor :previous_match_case
			attr_accessor :previous_wrap_around
    end

	  attr_accessor :initial_query


    ### UI ###

		# Override num_columns to control number of rows.
		def num_columns
			return 7
		end

    label :label_search, "Search:"
    textbox :query

    combo :search_type, ["Regex", "Plain", "Glob"], "RegEx" do |val|
      @@options_cache.search_type = val
    end

		toggle :match_case, 'Match case', nil, false do |val|
		  @@options_cache.match_case = val
		end

		toggle :wrap_around, 'Wrap Around', nil, true do |val|
		  @@options_cache.wrap_around = val
		end

		label :label_spacer_end_row1a, ""
		label :label_spacer_end_row1b, ""
		label :label_spacer_start_row2, ""

    label :label_replace, "Replace:"
    textbox :replace

    button :replace_find, 'Replace && Find', "Return" do
      update_options_from_ui(@@options_cache)
      success = SearchAndReplaceExtSpeedbar.replace_and_find(@@options_cache)
		end

    button :replace_all, "Replace All", nil do
			puts 'Replace All'
		end

		label :label_spacer_mid_row2, ""

		button :previous, "Previous", nil do
			puts 'Previous'
		end

		button :next, "Next", nil do
			puts 'Next'
		end

		# Initializes UI elements.
		def after_draw
		  options = @@options_cache
		  SearchSpeedbar.previous_query ||= ""
      self.query.value = @initial_query || SearchSpeedbar.previous_query || options.query
      self.replace.value = options.replace || ""
      self.search_type.value = SearchAndReplaceExtSpeedbar.search_type_to_text(options.search_type)
      self.match_case.value = options.match_case
      self.wrap_around.value = options.wrap_around
      self.query.edit_view.document.select_all
		end  # after_draw

    # description here
    def update_options_from_ui(options)
			options.query = query.value
      options.replace = replace.value
      options.search_type = SearchAndReplaceExtSpeedbar.search_type_to_symbol(search_type.value)
      options.match_case = match_case.value
      options.wrap_around = wrap_around.value
    end  # update_options_from_ui()


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

    # description here
    def self.replace_and_find(options)
      puts 'SearchAndReplaceExtSpeedbar.replace_and_find'
      #adoc = Redcar.app.focussed_notebook_tab.document
      cmd = ReplaceAndFindCommand.new(options)
      found_match = cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
      if not found_match then
        Redcar::Application::Dialog.message_box("No instance of the search string were found",
                                                {:type => :info, :buttons => :ok})
      end
    end  # self.replace_and_find

	end  # class SearchAndReplaceExtSpeedbar

end  # module DocumentSearch
