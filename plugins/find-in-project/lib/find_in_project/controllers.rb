require 'erb'
require 'cgi'

module Redcar
  class FindInProject
    class Controller
      include Redcar::HtmlController

      def title
        "Find In Project"
      end

      def index
        @plugin_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
        @settings = Redcar::FindInProject.storage
        @query = doc.selected_text if doc && doc.selection?
        render('index')
      end

      def search(query, literal_match, match_case, with_context)
        @query = query
        @literal_match = (literal_match == 'true')
        @match_case = (match_case == 'true')
        @with_context = (with_context == 'true')
        Redcar::FindInProject.storage['recent_queries'] = add_or_move_to_top(query, Redcar::FindInProject.storage['recent_queries'])

        execute("$('#cached_query').val(\"#{escape_javascript(@query)}\");")
        execute("$('#results').html(\"<div id='no_results'>Searching...</div>\");")
        execute("$('#results_summary').hide();")
        execute("$('#file_results_count').html(0);")
        execute("$('#line_results_count').html(0);")
        search_in_background

        nil
      end

      def open_file(file, line, query, literal_match, match_case)
        Project::Manager.open_file(File.join(Project::Manager.focussed_project.path, file))
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

      private

      def render(view)
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "views", "#{view.to_s}.html.erb")))
        rhtml.result(binding)
      end

      def doc
        Redcar.app.focussed_window.focussed_notebook_tab.edit_view.document rescue false
      end

      def add_or_move_to_top(item, array)
        return array if item.strip.empty?
        array.delete_at(array.index(item)) if array.include?(item)
        array.unshift(item)
      end

      def search_in_background
        @plugin_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
        @settings = Redcar::FindInProject.storage
        @project_path = Project::Manager.focussed_project.path

        # kill any existing running search to prevent memory bloat
        Thread.kill(@thread) if @thread
        @thread = nil

        @thread = Thread.new do
          found_lines = false
          last_file = nil

          @file_index, @line_index = 0, 0

          Redcar::FileParser.new(@project_path, @settings).each_line do |line, line_no, file, file_no|
            next unless matching_line?(line)

            # Add an initial <tr></tr>  so that tr:last can be used
            execute("if ($('#results table').size() == 0) { $('#results').html(\"<table><tr></tr></table>\"); }")
            execute("if ($('#results_summary').first().is(':hidden')) { $('#results_summary').show(); }")

            parsing_new_file = (!last_matching_line || last_matching_line.file != line.file)

            if parsing_new_file
              execute("$('#file_results_count').html(parseInt($('#file_results_count').html()) + 1);")
              execute("$('#results table tr:last').after(\"<tr><td class='break' colspan='2'></td></tr>\");") if matched_lines
              @file = line.file
              execute("$('#results table tr:last').after(\"#{escape_javascript(render('_file_heading'))}\");")
              @line_index = 0 # reset line row styling
            end

            @line_index, @line_no, @line = ((@line_index || 0) + 1), line_no, line
            execute("$('#results table tr:last').after(\"#{escape_javascript(render('_file_line'))}\");")

<<<<<<< HEAD
            found_lines = true
            last_file = file
=======
            execute("$('#line_results_count').html(parseInt($('#line_results_count').html()) + 1);")

            matched_lines = true
            last_matching_line = line
>>>>>>> 1c916706eb5f9da332209afba0cf443081b71a16
          end

          if found_lines
            # Remove the blank tr we added initially
            execute("$('#results table tr:first').remove();")
          else
            result = "<div id='no_results'>No results were found using the search terms you provided.</div>"
            execute("$('#results').html(\"#{escape_javascript(result)}\");")
          end

          Thread.kill(@thread) if @thread
          @thread = nil
        end
      end

      def matching_line?(line)
        regexp_text = @literal_match ? Regexp.escape(@query) : @query
        regexp = @match_case ? /#{regexp_text}/ : /#{regexp_text}/i
        line =~ regexp
      end

      def escape_javascript(javascript)
        escape_map = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
        javascript.to_s.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { escape_map[$1] }
      end
    end
  end
end
