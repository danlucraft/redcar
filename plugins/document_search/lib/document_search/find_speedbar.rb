module DocumentSearch
  class FindSpeedbar < Redcar::Speedbar
    @@previous_query = ''
    @@previous_options = SearchOptions.new

    attr_accessor :initial_query

    def doc
      win = Redcar.app.focussed_window
      tab = win.focussed_notebook_tab
      tab.document if tab
    end

    def after_draw
      @@previous_query ||= ""
      self.query.value = @initial_query || @@previous_query
      self.search_type.value = SearchOptions.search_type_to_text(@@previous_options.search_type)
      self.match_case.value = @@previous_options.match_case
      self.wrap_around.value = @@previous_options.wrap_around
      self.query.edit_view.document.select_all
    end

    label :label, "Find:"
    textbox :query do |value|
      if doc
        set_offset
        start_search
      end
    end

    combo :search_type, ["Plain", "Regex", "Glob"], "Plain" do |val|
      @@previous_options.search_type = SearchOptions.search_type_to_symbol(val)
      update_search
    end

    toggle :match_case, 'Match case', nil, false do |val|
      @@previous_options.match_case = val
      update_search
    end

    toggle :wrap_around, 'Wrap Around', nil, true do |val|
      @@previous_options.wrap_around = val
      update_search
    end

    button :search, "Find", "Return" do
      if doc
        @offset = nil
        doc.set_selection_range(doc.cursor_offset,0)
        start_search
      end
    end

    def start_search
      if doc
        @@previous_query = self.query.value
        @@previous_options.search_type = SearchOptions.search_type_to_symbol(self.search_type.value)
        @@previous_options.match_case = self.match_case.value
        @@previous_options.wrap_around = self.wrap_around.value
        success = FindSpeedbar.find_next
      end
    end

    def update_search
      if doc and self.query.value and self.query.value != ""
        set_offset
        FindSpeedbar.previous_query = self.query.value
        FindSpeedbar.find_next
      end
    end

    def set_offset
      @offset = doc.cursor_offset unless @offset
      if doc.selection?
        if doc.selection_offset != @offset + doc.selected_text.length
          @offset = [doc.cursor_offset, doc.selection_offset].min
        end
      else
        @offset = doc.cursor_offset
      end
      doc.cursor_offset = @offset
      puts "OFFSET: #{doc.cursor_offset}"
    end

    def self.find_next
      cmd = FindNextCommand.new(@@previous_query, @@previous_options)
      cmd.run(:env => {:edit_view => Redcar::EditView.focussed_tab_edit_view})
    end
  end
end