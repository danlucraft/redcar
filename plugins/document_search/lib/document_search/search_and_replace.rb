
module DocumentSearch
  class SearchAndReplaceSpeedbar < Redcar::Speedbar
    class << self
      attr_accessor :previous_query
      attr_accessor :previous_replace
      attr_accessor :previous_search_type
    end
    
    def after_draw
      self.query.value = SearchAndReplaceSpeedbar.previous_query || ""
      self.replace.value = SearchAndReplaceSpeedbar.previous_replace || ""
      self.search_type.value = SearchAndReplaceSpeedbar.previous_search_type
      self.query.edit_view.document.select_all
    end
    
    label :label_search, "Search:"
    textbox :query
    
    label :label_replace, "Replace:"
    textbox :replace
    
    combo :search_type, ["Regex", "Plain", "Glob"], "RegEx" do |v|
      SearchAndReplaceSpeedbar.previous_search_type = v
    end
    
    button :single_replace, "Replace", "Return" do
      SearchAndReplaceSpeedbar.previous_query = query.value
      SearchAndReplaceSpeedbar.previous_replace = replace.value
      SearchAndReplaceSpeedbar.previous_search_type = search_type.value || "Regex" # Hack to work around fact that default value not being picked up
      success = SearchAndReplaceSpeedbar.search_replace
    end
    
    button :all_replace, "Replace All", nil do
      SearchAndReplaceSpeedbar.previous_query = query.value
      SearchAndReplaceSpeedbar.previous_replace = replace.value
      SearchAndReplaceSpeedbar.previous_search_type = search_type.value || "Regex" # Hack to work around fact that default value not being picked up
      success = SearchAndReplaceSpeedbar.search_replace_all
    end
    
    def self.search_replace
      current_query = @previous_query
      current_replace = @previous_replace
      case @previous_search_type
      when "Regex"
        search_method = Search.method(:regex_search_method)
      when "Plain"
        search_method = Search.method(:plain_search_method)
      when "Glob"
        search_method = Search.method(:glob_search_method)
      else
        search_method = Search.method(:regex_search_method)
      end
      adoc = Redcar.app.focussed_notebook_tab.document
      count = Replace.new(adoc).replace_next(current_query, current_replace, &search_method)
      if count == 0
        Redcar::Application::Dialog.message_box("No instance of the search string were found", {:type => :info, :buttons => :ok})
      end
    end
    
    def self.search_replace_all
      current_query = @previous_query
      current_replace = @previous_replace
      case @previous_search_type
      when "Regex"
        search_method = Search.method(:regex_search_method)
      when "Plain"
        search_method = Search.method(:plain_search_method)
      when "Glob"
        search_method = Search.method(:glob_search_method)
      else
        search_method = Search.method(:regex_search_method)
      end
      adoc = Redcar.app.focussed_notebook_tab.document
      count = Replace.new(adoc).replace_all(current_query, current_replace, &search_method)
      if count == 0 or count > 1
        message = "Replaced #{count} occurrences"
      else
        message = "Replaced #{count} occurrence"
      end
      Redcar::Application::Dialog.message_box(message, {:type => :info, :buttons => :ok})
    end
  end
end
