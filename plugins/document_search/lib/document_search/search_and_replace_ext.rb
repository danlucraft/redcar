
module DocumentSearch

	class SearchAndReplaceExtSpeedbar < Redcar::Speedbar
    class << self
      attr_accessor :previous_query
      attr_accessor :previous_replace
      attr_accessor :previous_search_type
			attr_accessor :previous_match_case
			attr_accessor :previous_wrap_around
    end

	  attr_accessor :initial_query

		# Override num_columns to control number of rows.
		def num_columns
			return 7
		end

    label :label_search, "Search:"
    textbox :query

    combo :search_type, ["Regex", "Plain", "Glob"], "RegEx" do |v|
      SearchAndReplaceExtSpeedbar.previous_search_type = v
    end

		toggle :match_case, 'Match case', nil, false do |v|
		  SearchAndReplaceExtSpeedbar.previous_match_case = v
#		  update_search
		end

		toggle :wrap_around, 'Wrap Around', nil, true do |v|
		  SearchAndReplaceExtSpeedbar.previous_wrap_around = v
#		  update_search
		end

		label :label_spacer_end_row1a, ""
		label :label_spacer_end_row1b, ""
		label :label_spacer_start_row2, ""

    label :label_replace, "Replace:"
    textbox :replace

    button :replace_find, 'Replace && Find', "What?" do
			puts 'Replace & Find'
		end

    button :replace_all, "Replace All", "What?" do
			puts 'Replace All'
		end

		label :label_spacer_mid_row2, ""

		button :previous, "<<", nil do
			puts 'Previous'
		end

		button :next, ">>", nil do
			puts 'Next'
		end


	end  # class SearchAndReplaceExtSpeedbar

end  # module DocumentSearch
