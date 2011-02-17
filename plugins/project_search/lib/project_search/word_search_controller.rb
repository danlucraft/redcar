
class ProjectSearch
  class WordSearchController
    include Redcar::HtmlController

    TITLE = "Project Search"

    def title
      TITLE
    end
    
    def search_copy
      "Search for complete words only"
    end
    
    def show_literal_match_option?
      false
    end

    def num_context_lines
      settings['context_lines']
    end
    
    def plugin_root
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    end
    
    def settings
      ProjectSearch.storage
    end
    
    def match_case?
      ProjectSearch.storage['match_case']
    end
    
    def context?
      ProjectSearch.storage['with_context']
    end
    
    def context_size
      context? ? num_context_lines : 0
    end
    
    def default_query
      doc.selected_text if doc && doc.selection?
    end
    
    def index
      render('index')
    end

    def edit_preferences
      Redcar.app.make_sure_at_least_one_window_open # open a new window if needed
      Redcar::FindInProject.storage # populate the file if it isn't already
      tab  = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
      mirror = Project::FileMirror.new(File.join(Redcar.user_dir, "storage", "find_in_project.yaml"))
      tab.edit_view.document.mirror = mirror
      tab.edit_view.reset_undo
      tab.focus
    end

    def open_file(file, line, query, literal_match, match_case)
      Redcar::Project::Manager.open_file(File.expand_path(file, Redcar::Project::Manager.focussed_project.path))
      doc.cursor_offset = doc.offset_at_line(line.to_i - 1)
      regexp_text = literal_match ? Regexp.escape(query) : query
      regex = match_case ? /(#{regexp_text})/ : /(#{regexp_text})/i
      index = doc.get_line(line.to_i - 1).index(regex)
      if index
        length = doc.get_line(line.to_i - 1).match(regex)[1].length
        doc.set_selection_range(doc.cursor_line_start_offset + index, doc.cursor_line_start_offset + index + length)
      end
      doc.scroll_to_line(line.to_i)
      nil
    end

    def close
      Thread.kill(@thread) if @thread
      @thread = nil
      super
    end
    
    def render(view, bg=nil)
      erb(view).result(bg || binding)
    end
    
    def render_file(bg)
      @erb ||= erb("_file")
      @erb.result(bg)
    end
    
    def erb(view)
      ERB.new(File.read(File.join(File.dirname(__FILE__), "views", "#{view.to_s}.html.erb")))
    end
    
    def doc
      Redcar.app.focussed_window.focussed_notebook_tab.edit_view.document rescue false
    end

    def add_or_move_to_top(item, array)
      return array if item.strip.empty?
      array.delete_at(array.index(item)) if array.include?(item)
      array.unshift(item)
    end

    def search(query, literal_match, match_case, with_context)
      ProjectSearch.storage['recent_queries'] = add_or_move_to_top(query, ProjectSearch.storage['recent_queries'])
      ProjectSearch.storage['match_case']     = (match_case == 'true')
      ProjectSearch.storage['with_context']   = (with_context == 'true')
      
      project = Redcar::Project::Manager.focussed_project
      
      @word_search = WordSearch.new(project, query, match_case?, context_size)
      
      # kill any existing running search to prevent memory bloat
      Thread.kill(@thread) if @thread
      @thread = nil
      @thread = Thread.new do
        begin
          initialize_search_output
          file_num = 0
          line_num = 0
          have_prepared_table = false
          have_results = false
          
          @word_search.on_file_results do |hits|
            next unless hits.any?
            have_results = true
            file_num += 1
            line_num += hits.length
            set_file_count(file_num)
            set_line_count(line_num)
            file = hits.first.file
            
            unless have_prepared_table
              prepare_results_table
              have_prepared_table = true
            end

            file_html = render_file(binding)
            escaped_file_html = escape_javascript(file_html)
            execute("$('#results table tr:last').after(\"#{escaped_file_html}\");")
          end
          
          @word_search.generate_results
          
          if have_results
            remove_initial_blank_tr
          else
            render_no_results
          end
          
          hide_spinner
          Thread.kill(@thread) if @thread
          @thread = nil
        rescue => e
          puts e.message
          puts e.backtrace
        end
      end
      nil
    end
    
    def initialize_search_output
      execute("$('#cached_query').val(\"#{escape_javascript(@word_search.query_string)}\");")
      execute("$('#results').html(\"<div id='no_results'>Searching...</div>\");")
      execute("$('#spinner').show();")
      execute("$('#results_summary').hide();")
      execute("$('#file_results_count').html(0);")
      execute("$('#line_results_count').html(0);")
    end
    
    def prepare_results_table
      execute("if ($('#results table').size() == 0) { $('#results').html(\"<table><tr></tr></table>\"); }")
      execute("if ($('#results_summary').first().is(':hidden')) { $('#results_summary').show(); }")
    end
    
    def set_file_count(value)
      execute("$('#file_results_count').html(\"#{value}\");")
    end
    
    def set_line_count(value)
      execute("$('#line_results_count').html(\"#{value}\");")
    end
    
    def remove_initial_blank_tr
      execute("$('#results table tr:first').remove();")
    end

    def render_no_results
      result = "<div id='no_results'>No results were found using the search terms you provided.</div>"
      execute("$('#results').html(\"#{escape_javascript(result)}\");")
    end
    
    def hide_spinner
      execute("$('#spinner').hide();")
    end

    def escape_javascript(text)
      escape_map = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
      text.to_s.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { escape_map[$1] }
    end

    def image_path
      File.expand_path(File.join(plugin_root, %w(lib project_search images)))
    end
  end
end