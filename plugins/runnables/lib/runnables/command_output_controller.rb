
module Redcar
  class Runnables
    class CommandOutputController
      include Redcar::HtmlController
      
      def initialize(path, cmd, title)
        @path = path
        @cmd = cmd
        @title = title
      end
      
      def title
        @title
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
        case Redcar.platform
        when :osx, :linux
          run_posix
        when :windows
          run_windows
        end
      end
      
      def stylesheet_link_tag(*files)
        files.map do |file|
          path = File.join(Redcar.root, %w(plugins runnables views) + [file.to_s + ".css"])
          url = "file://" + File.expand_path(path)
          %Q|<link href="#{url}" rel="stylesheet" type="text/css" />|
        end.join("\n")
      end
      
      def process(text)
        @processor ||= OutputProcessor.new
        @processor.process(text)
      end
      
      def run_windows
        @thread = Thread.new do
          output = `cd #{@path} & #{@cmd} 2>&1`
          html=<<-HTML
          <div class="stdout">
            #{process(output)}
          </div>
          HTML
          execute(<<-JAVASCRIPT)
            $("#output").append(#{html.inspect});
            $("html, body").attr({ scrollTop: $("#output").attr("scrollHeight") }); 
          JAVASCRIPT
        end
      end
      
      def run_posix
        @thread = Thread.new do
          sleep 1
          @shell = Session::Shell.new
          @shell.outproc = lambda do |out|
            html=<<-HTML
              <div class="stdout">
                #{process(out)}
              </div>
            HTML
            execute(<<-JAVASCRIPT)
              $("#output").append(#{html.inspect});
              $("html, body").attr({ scrollTop: $("#output").attr("scrollHeight") }); 
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
              $("html, body").attr({ scrollTop: $("#output").attr("scrollHeight") }); 
            JAVASCRIPT
          end
          begin
            @shell.execute("cd #{@path}; " + @cmd)
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
            $("html, body").attr({ scrollTop: $("#output").attr("scrollHeight") }); 
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

