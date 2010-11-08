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
        @literal_match = Redcar::FindInProject.storage['literal_match']
        @match_case = Redcar::FindInProject.storage['match_case']
        @with_context = Redcar::FindInProject.storage['with_context']
        render('index')
      end

      def search(query, literal_match, match_case, with_context)
        @query = query
        Redcar::FindInProject.storage['recent_queries'] = add_or_move_to_top(@query, Redcar::FindInProject.storage['recent_queries'])
        Redcar::FindInProject.storage['literal_match'] = (@literal_match = (literal_match == 'true'))
        Redcar::FindInProject.storage['match_case'] = (@match_case = (match_case == 'true'))
        Redcar::FindInProject.storage['with_context'] = (@with_context = (with_context == 'true'))

        execute("$('#cached_query').val(\"#{escape_javascript(@query)}\");")
        execute("$('#results').html(\"<div id='no_results'>Searching...</div>\");")
        execute("$('#spinner').show();")
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
      
      def preferences
        Redcar.app.make_sure_at_least_one_window_open # open a new window if needed

        Redcar::FindInProject.storage # populate the file if it isn't already

        tab  = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
        mirror = Project::FileMirror.new(File.join(Redcar.user_dir, "storage", "find_in_project.yaml"))
        tab.edit_view.document.mirror = mirror
        tab.edit_view.reset_undo
        tab.focus
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
          matched_lines = false
          last_matching_line = nil

          Redcar::FileParser.new(@project_path, @settings).each_line do |line|
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

            if @with_context && !parsing_new_file && (line.num - last_matching_line.num) > (@settings['context_lines'] * 2)
              execute("$('#results table tr:last').after(\"#{escape_javascript(render('_divider'))}\");")
            end

            context = line.context(@settings['context_lines']) if @with_context
            context[:before].each { |b_line| render_line(b_line) } if @with_context
            render_line(line)
            context[:after].each { |a_line| render_line(a_line) } if @with_context

            execute("$('#line_results_count').html(parseInt($('#line_results_count').html()) + 1);")

            matched_lines = true
            last_matching_line = line
          end

          if matched_lines
            # Remove the blank tr we added initially
            execute("$('#results table tr:first').remove();")
          else
            result = "<div id='no_results'>No results were found using the search terms you provided.</div>"
            execute("$('#results').html(\"#{escape_javascript(result)}\");")
          end

          execute("$('#spinner').hide();")

          Thread.kill(@thread) if @thread
          @thread = nil
        end
      end

      def matching_line?(line)
        regexp_text = @literal_match ? Regexp.escape(@query) : @query
        regexp = @match_case ? /#{regexp_text}/ : /#{regexp_text}/i
        line.text =~ regexp
      end

      def escape_javascript(text)
        escape_map = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
        text.to_s.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { escape_map[$1] }
      end

      def render_line(line)
        @line_index += 1
        @line, @file = line, line.file
        execute("if ($('#results tr.file_#{@file.num}.line_#{@line.num}').size() == 0) {
          $('#results table tr:last').after(\"#{escape_javascript(render('_file_line'))}\");
        }")
      end
    end
  end
end
