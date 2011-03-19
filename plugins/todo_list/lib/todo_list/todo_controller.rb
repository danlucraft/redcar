module Redcar
  class TodoList
    class TodoController
      include HtmlController

      def initialize(path)
        @path = path
      end

      def title
        "Todo List"
      end

      # Open a text file in a new edit tab
      def open_file(options)
        path = options.keys.first
        line = options.values.first.first.to_i
        if File.exists? path
          Project::OpenFileCommand.new(path).run
          tab = Redcar.app.focussed_notebook_tab
          document = tab.edit_view.document
          if line <= document.line_count
            offset = document.offset_at_line(line)
            document.cursor_offset = offset
            document.scroll_to_line(line)
          end
          tab.focus
        else
          Application::Dialog.message_box "File #{path} could not be found."
        end
        false
      end

      def populate_list
        @thread = Thread.new do
          sleep 1
          execute(open_page)
          @tag_list = TodoList::FileParser.new.parse_files(@path)

          TodoList.storage['tags'].each do |tag|
            execute(%{ $("#tags").append(#{html_table_for(tag).inspect}); })
          end
          @tag_list.each_pair do |tag, todo_items|
            todo_items.each do |item|
              execute(%{ $("##{table_id(tag)}").append(#{html_tr_for(item).inspect}); })
            end
          end
          execute(finalize_page)
        end
      end

      def html_table_for(tag)
        <<-HTML
          <br/>
          <table id="#{table_id(tag)}" width="100%">
            <tr>
              <th bgcolor="#ffffcc" colspan="2">#{tag}</th>
            </tr>
          </table>
        HTML
      end

      def html_tr_for(item)
        display_path = item.path[@path.length..-1]
        <<-HTML
          <tr>
            <td bgcolor="#ccffcc" width="40%"><a class="action">#{item.action}</a></td>
            <td bgcolor="#dddddd"><a class="file_path" href="controller/open_file?#{item.path}=#{item.line}">#{display_path}:#{item.line+1}</a></td>
          </tr>
        HTML
      end

      def table_id(tag)
        "#{tag}_table"
      end

      def open_page
        <<-JAVASCRIPT
          $("#status").html("Searching...");
          $("#tags").html(" ");
        JAVASCRIPT
      end

      def finalize_page
        <<-JAVASCRIPT
          $("#status").remove();
          $("#final_status").html("Search complete.");
          $("#refresh").html("Refresh List");
        JAVASCRIPT
      end

      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..","..", "views", "index.html.erb")))
        populate_list
        rhtml.result(binding)
      end
    end
  end
end