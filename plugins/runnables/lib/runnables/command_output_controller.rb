
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
      
      def run_windows
        @thread = Thread.new do
          output = `cd #{@path} & #{@cmd} 2>&1`
          html=<<-HTML
          <div class="stdout">
            <pre>#{output}</pre>
          </div>
          HTML
          execute(<<-JAVASCRIPT)
            $("#output").append(#{html.inspect});
          JAVASCRIPT
        end
      end
      
      # From TextMate's Support/lib/escape.rb
      # Make string suitable for display as HTML, preserve spaces. Set :no_newline_after_br => true
      # to cause “\n” to be substituted by “<br>” instead of “<br>\n”
      def htmlize(str, opts = {}) 
        str = str.to_s.gsub("&", "&amp;").gsub("<", "&lt;")
        str = str.gsub(/\t+/, '<span style="white-space:pre;">\0</span>')
        str = str.reverse.gsub(/ (?= |$)/, ';psbn&').reverse
        if opts[:no_newline_after_br].nil?
          str.gsub("\n", "<br>\n")
        else
          str.gsub("\n", "<br>")
        end 
      end
      
      def run_posix
        @thread = Thread.new do
          sleep 1
          @shell = Session::Shell.new
          @shell.outproc = lambda do |out|
            html=<<-HTML
              <div class="stdout">
                #{htmlize(out)}
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

