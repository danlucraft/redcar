
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
      
      def run
        Thread.new do
          shell = Session::Shell.new
          shell.outproc = lambda do |out|
            html=<<-HTML
              <div class="stdout">
                <pre>#{out}</pre>
              </div>
            HTML
            execute(<<-JAVASCRIPT)
              $("#output").append(#{html.inspect});
            JAVASCRIPT
          end
          shell.errproc = lambda do |err|
            p err
            html=<<-HTML
              <div class="stderr">
                <pre>#{err}</pre>
              </div>
            HTML
            p html
            execute(<<-JAVASCRIPT)
              $("#output").append(#{html.inspect});
            JAVASCRIPT
          end
          shell.execute(@cmd)
          html=<<-HTML
          <hr />
          <small><strong>Process finished</strong></small>
          HTML
          execute(<<-JAVASCRIPT)
            $("#output").append(#{html.inspect});
          JAVASCRIPT
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
