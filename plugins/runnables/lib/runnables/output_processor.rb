module Redcar
  class Runnables
    class OutputProcessor
      # From TextMate's Support/lib/escape.rb
      # Make string suitable for display as HTML, preserve spaces. Set :no_newline_after_br => true
      # to cause “\n” to be substituted by “<br>” instead of “<br>\n”
      def process(str, opts = {})
        str = str.to_s.gsub("&", "&amp;").gsub("<", "&lt;")
        str = process_ansi(str)
        str = process_file_line_numbers(str)
        str = str.gsub(/\t+/, '<span style="white-space:pre;">\0</span>')
        str = str.reverse.gsub(/ (?= |$)/, ';psbn&').reverse
        if opts[:no_newline_after_br].nil?
          str = str.gsub("\n", "<br>\n")
        else
          str = str.gsub("\n", "<br>")
        end
      end
      
      def process_file_line_numbers(str)
        file_number_regex = /(\S+)\:(\d+)/
        if str =~ file_number_regex
          str.gsub(file_number_regex,
            %{<a class="file_line_link" href="javascript:Controller.openFile('#{$1}', '#{$2}');">#{$1}:#{$2}</a>})
        else
          str
        end
      end
    
      def initialize
        @ansi_stack = []
        @ansi_colors = %w(black red green yellow blue purple cyan gray)
      end
      
      def color(num)
        @ansi_colors[num.to_i]
      end

      def close_ansi_spans(clear = false)
        stack_length = @ansi_stack.size
        @ansi_stack = [] if clear
        "</span>" * stack_length
      end

      def ansi_span(style)
        %Q|<span class="#{style}">|
      end

      def restart_ansi_spans
        @ansi_stack.map do |style|
          ansi_span(style)
        end.join('')
      end

      def process_ansi(str)
        restart_ansi_spans + str.gsub(/\e\[(([0,1]);?)?((\d)(\d))?m/) do |m|
          match = $~
          if match[2] == "0" && match[4].nil?
            close_ansi_spans(:clear)
          else
            style = ""
            style << "ansi-regular "               if match[2] == "0"
            style << "ansi-bold "                  if match[2] == "1"
            style << "ansi-light "                 if match[4] == "9"
            style << "ansi-on-#{color(match[5])} " if match[4] == "4"
            style << "ansi-#{color(match[5])}"     if match[4] == "3" || match[4] == "9"
            @ansi_stack << style unless style.empty?
            ansi_span(style)
          end
        end + close_ansi_spans
      end
    end
  end
end
