require 'erb'
require 'cgi'

module Redcar
  class FindInProject
    class Controller
      include Redcar::HtmlController

      def title
        "Find In Project"
      end

      def doc
        Redcar.app.focussed_window.focussed_notebook_tab.edit_view.document rescue false
      end

      def index
        @plugin_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
        @settings = Redcar::FindInProject.storage

        @query = doc.selected_text if doc && doc.selection?
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "views", "index.html.erb")))
        rhtml.result(binding)
      end

      def search(query, options, match_case)
        @query = query
        @options = options
        @match_case = (match_case == 'true')

        Redcar::FindInProject.storage['recent_queries'] = add_or_move_to_top(@query, Redcar::FindInProject.storage['recent_queries'])
        Redcar::FindInProject.storage['recent_options'] = add_or_move_to_top(@options, Redcar::FindInProject.storage['recent_options'])

        @results = case Redcar::FindInProject.storage['search_engine']
        when 'grep'
          Redcar::FindInProject::Engines::Grep.search(@query, @options, @match_case)
        when 'ack'
          Redcar::FindInProject::Engines::Ack.search(@query, @options, @match_case)
        end

        Redcar.app.focussed_window.focussed_notebook_tab.html_view.controller = self
        nil
      end

      def add_or_move_to_top(item, array)
        return array if item.strip.empty?
        array.delete_at(array.index(item)) if array.include?(item)
        array.unshift(item)
      end

      def open_file(file, line, query, match_case)
        Project::Manager.open_file(File.join(Project::Manager.focussed_project.path, file))
        doc.cursor_offset = doc.offset_at_line(line.to_i - 1)
        regex = match_case ? /(#{query})/ : /(#{query})/i
        index = doc.get_line(line.to_i - 1).index(regex)
        length = doc.get_line(line.to_i - 1).match(regex)[1].length
        doc.set_selection_range(doc.cursor_line_start_offset + index, doc.cursor_line_start_offset + index + length)
        doc.scroll_to_line(line.to_i)
        nil
      end
    end
  end
end
