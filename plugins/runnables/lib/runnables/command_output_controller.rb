
module Redcar
  class Runnables
    class CommandOutputController
      include Redcar::HtmlController
      
      attr_accessor :cmd

      def initialize(path, cmd, title)
        @path = path
        @cmd = cmd
        @title = title
        @output_id = 0
      end
      
      def title
        @title
      end
      
      def ask_before_closing
        if @pid
          "This tab contains an unfinished process. \n\nKill the process and close?"
        end
      end
      
      def close
        if @pid
          Process.kill(9, @pid.to_i + 1)
        end
      end
      
      def run
        case Redcar.platform
        when :osx, :linux
          cmd = "sh -c \"cd #{@path}; #{@cmd}\""
        when :windows
          cmd = "cd \"#{@path.gsub('/', '\\')}\" & #{@cmd}"
        end
        run_command(cmd)
      end
      
      def copy_output(text)
        Redcar.app.clipboard << text
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
      
      def output_thread(type, output)
        Thread.new(output) do
          instance_variable_set("@#{type}_thread_started", true)
          begin
            while line = output.gets
              append_output %Q|<div class="#{type}">#{process(line)}</div>|
            end
          rescue => e
            puts e.class
            puts e.message
            puts e.backtrace
          end
        end
      end
      
      def run_command(cmd)
        Thread.new do
          execute <<-JS
            $('.actions').hide();
            $('.output').slideUp().prev('.header').addClass('up');
          JS
          
          # TODO: Find browser's onload rather than sleeping
          sleep 1
          start_output_block
          Redcar.log.info "Running: #{cmd}"
          
          # JRuby-specific
          @pid, input, output, error = IO.popen4(cmd)
          @stdout_thread = output_thread(:stdout, output)
          @stderr_thread = output_thread(:stderr, error)
          
          Thread.new do
            sleep 0.1 until finished?
            @pid = nil
            end_output_block
          end
        end
      end
      
      def finished?
        @stdout_thread_started && @stderr_thread_started &&
          !@stdout_thread.alive? && !@stderr_thread.alive?
      end
      
      def format_time(time)
        time.strftime("%I:%M:%S %p").downcase
      end

      def start_output_block
        @start = Time.now
        @output_id += 1
        append_to_container <<-HTML
          <div class="process running">
            <div id="header#{@output_id}" class="header" onclick="$(this).toggleClass('up').next().slideToggle();">
              <span class="in-progress-message">Started at #{format_time(@start)}</span>
            </div>
            <div id="output#{@output_id}" class="output"></div>
          </div>
        HTML
      end

      def end_output_block
        @end = Time.now
        append_to(header_container, <<-HTML)
          <span class="completed-message">
            Completed at #{format_time(@end)}. (Took #{@end - @start} seconds)
          </span>
        HTML
        execute <<-JS
          $('<a href="#" class="copy">Copy output to clipboard</a>').click(function () {
            Controller.copyOutput($("#{output_container}").text());
            return false;
          }).appendTo('#{header_container}');
          $("#{output_container}").parent().removeClass("running");
          $('.actions').show();
          $("html, body").attr({ scrollTop: $("body").attr("scrollHeight") });
        JS
      end

      def scroll_to_end(container)
        execute <<-JS
          $("html, body").attr({ scrollTop: $("body").attr("scrollHeight") });
        JS
      end
      
      def append_to(container, html)
        execute(<<-JS)
          $(#{html.inspect}).appendTo("#{container}");
        JS
      end

      def append_to_container(html)
        append_to("#container", html)
        scroll_to_end("#container")
      end

      def header_container
        "#header#{@output_id}"
      end

      def output_container
        "#output#{@output_id}"
      end

      def append_output(output)
        append_to(output_container, output)
        scroll_to_end(output_container)
      end

      def open_file(file, line)
        Project::Manager.open_file(File.join(Project::Manager.focussed_project.path, file))
        Redcar.app.focussed_window.focussed_notebook_tab.edit_view.document.scroll_to_line(line.to_i)
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

