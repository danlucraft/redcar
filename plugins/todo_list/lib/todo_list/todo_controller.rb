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

      def debug
        false
      end

      # Open a text file in a new edit tab
      def open_file(path)
        path = path.to_s
        #check for line number
        idx = path.rindex(":")
        line = 1
        unless idx.nil?
          # line number found
          line = path[idx+1,path.length]
          # convert path to actual file path
          path = path[0,idx]
        end
        if File.exists?(path)
          puts "Opening #{path} in new tab" if debug
          Project::FileOpenCommand.new(path).run
          tab  = Redcar.app.focussed_notebook_tab
          #check if line is a number
          if numeric?(line)
            line = line.to_i - 1
            if line >= 0
              document = tab.edit_view.document
              if line <= document.line_count.to_i
                puts "scrolling to line number: #{line}" if debug
                offset = document.offset_at_line(line)
                document.cursor_offset = offset
                document.scroll_to_line(line)
              end
            end
          end
          tab.focus
        end
        false
      end

      def numeric?(object)
        true if Integer(object) rescue false
      end

      def parse_path(path,tag)
        idx = tag.length
        if TodoList.storage['require_colon']
          idx += 1
        end
        path = path[idx,path.length]
        display_path = path[@path.length+1,path.length]
        case Redcar.platform
        when :osx, :linux
          display_path = display_path.gsub("//","/")
        when :windows
          display_path = display_path.gsub("//","\\")
        end
        puts "Final path: #{path}" if debug
        puts "Path for display: #{display_path}" if debug
        [path, display_path]
      end

      def populate_list
        @thread = Thread.new do
          sleep 1
          execute(<<-JAVASCRIPT)
              $("#status").html("Searching...");
              $("#tags").html(" ");
          JAVASCRIPT
          s = Time.now
          @tag_list = TodoList::FileParser.new.parse_files(@path) || {}
          i = 0
          total = @tag_list.to_a.length.to_i - 1
          TodoList.storage['tags'].each do |tag|
            table_id = "#{tag}_table"
            html=<<-HTML
              <br/>
              <table id="#{table_id}" width="100%">
                <tr>
                  <th bgcolor="#ffffcc" colspan="2">#{tag}</th>
                </tr>
              </table>
            HTML
            execute(<<-JAVASCRIPT)
            $("#tags").append(#{html.inspect});
            JAVASCRIPT
            @tag_list.each do |path,action|
              if path[0,tag.length] == tag
                puts "#{i} of #{total}" if debug
                path, display_path = parse_path(path,tag)
                html=<<-HTML
                  <tr>
                    <td  bgcolor="#ccffcc" width="40%"><a class="action">#{action}</a></td>
                    <td><a class="file_path" href="controller/open_file?#{path}">#{display_path}</a></td>
                  </tr>
                HTML
                percentage = 100
                if total > 0
                  percentage = ((i.to_f/total.to_f)*100).to_i
                end
                execute(<<-JAVASCRIPT)
                $("#status").html("Populating... #{percentage}%");
                $("##{table_id}").append(#{html.inspect});
                JAVASCRIPT
                break if i.to_i == total.to_i
                i+= 1
              end
            end
          end
          execute(<<-JAVASCRIPT)
            $("#status").remove();
            $("#final_status").html("Search completed in #{Time.now - s} seconds");
            $("#refresh").html("Refresh List");
            JAVASCRIPT
        end
        @thread = nil
      end

      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..","..", "views", "index.html.erb")))
        populate_list
        rhtml.result(binding)
      end
    end
  end
end