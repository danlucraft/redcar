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

      def search(query, options, match_case, with_context)
        @query = query
        @options = options
        @match_case = (match_case == 'true')
        @with_context = (with_context == 'true')
        Redcar::FindInProject.storage['recent_queries'] = add_or_move_to_top(@query, Redcar::FindInProject.storage['recent_queries'])
        Redcar::FindInProject.storage['recent_options'] = add_or_move_to_top(@options, Redcar::FindInProject.storage['recent_options'])
        search_in_background
        nil
      end

      def open_file(file, line, query, match_case)
        Project::Manager.open_file(File.join(Project::Manager.focussed_project.path, file))
        doc.cursor_offset = doc.offset_at_line(line.to_i - 1)
        regex = match_case ? /(#{query})/ : /(#{query})/i
        index = doc.get_line(line.to_i - 1).index(regex)
        if index
          length = doc.get_line(line.to_i - 1).match(regex)[1].length
          doc.set_selection_range(doc.cursor_line_start_offset + index, doc.cursor_line_start_offset + index + length)
        end
        doc.scroll_to_line(line.to_i)
        nil
      end

      def close
        @thread = nil # stop ant running searches
      end

      private

      def render(action)
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "views", "#{action}.html.erb")))
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

      def search_class
        @search_class ||= case Redcar::FindInProject.storage['search_engine']
        when 'grep'
          Redcar::FindInProject::Engines::Grep
        when 'ack'
          Redcar::FindInProject::Engines::Ack
        end
      end

      def search_in_background
        execute("$('#results_container').html(\"<div id='searching'>Searching...</div>\");")

        @thread = Thread.new do
          begin
            @results = search_class.search(@query, @options, @match_case, @with_context)
            render_results
          rescue => e
            error = "<div id='errors'>
              Opps! Something went wrong when trying to search!<br />
              #{CGI.escapeHTML(e.message)}<br />
              #{e.backtrace.collect { |b| CGI.escapeHTML(b) }.join('<br />')}
            </div>"
            execute("$('#results_container').html(\"#{escape_javascript(error)}\");")
          end
          @thread = nil
        end
      end

      def render_results
        if @results.nil? || @results.empty?
          results = "<div id='no_results'>No results were found using the search terms you provided.</div>"
        else
          results = render('_results')
        end
        execute("$('#results_container').html(\"#{escape_javascript(results)}\");")
      end

      def escape_javascript(javascript)
        escape_map = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
        javascript.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { escape_map[$1] }
      end
    end
  end
end
