
module Redcar
  class Runnables
    class CommandOutputController
      include Redcar::HtmlController
      
      def initialize(cmd)
        @cmd = cmd
      end
      
      def title
        "Process"
      end
      
      def ask_before_closing
        if @shell
          "This tab contains an unfinished process. \n\nKill the process and close?"
        end
      end
      
      def close
        if @shell
          Process.kill(9, @shell.pid.to_i + 1)
        end
      end
      
      def run
        @thread = Thread.new do
          sleep 1
          @shell = Session::Shell.new
          @shell.outproc = lambda do |out|
            html=<<-HTML
              <div class="stdout">
                <pre>#{out}</pre>
              </div>
            HTML
            execute(<<-JAVASCRIPT)
              $("#output").append(#{html.inspect});
            JAVASCRIPT
          end
          @shell.errproc = lambda do |err|
            html=<<-HTML
              <div class="stderr">
                <pre>#{err}</pre>
              </div>
            HTML
            execute(<<-JAVASCRIPT)
              $("#output").append(#{html.inspect});
            JAVASCRIPT
          end
          begin
            @shell.execute(@cmd)
          rescue => e
            puts e.class
            puts e.message
            puts e.backtrace
          end
          html=<<-HTML
          <hr />
          <small><strong>Process finished</strong></small>
          HTML
          execute(<<-JAVASCRIPT)
            $("#output").append(#{html.inspect});
          JAVASCRIPT
          @shell = nil
          @thread = nil
        end
      end        
      
      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "..", "views", "command_output.html.erb")))
        command = @cmd
        run
        rhtml.result(binding)
      end
    end
  end
end

#   $("#output").append("#{out.gsub("\"", "\\\"")}")
