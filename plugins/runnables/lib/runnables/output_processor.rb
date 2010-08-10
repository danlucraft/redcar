module Redcar
  class Runnables
    class OutputProcessor
      # From TextMate's Support/lib/escape.rb
      # Make string suitable for display as HTML, preserve spaces. Set :no_newline_after_br => true
      # to cause “\n” to be substituted by “<br>” instead of “<br>\n”
      def process(str, opts = {})
        str = str.to_s.gsub("&", "&amp;").gsub("<", "&lt;")
        str = process_ansi(str)
        str = str.gsub(/\t+/, '<span style="white-space:pre;">\0</span>')
        str = str.reverse.gsub(/ (?= |$)/, ';psbn&').reverse
        if opts[:no_newline_after_br].nil?
          str.gsub("\n", "<br>\n")
        else
          str.gsub("\n", "<br>")
        end 
      end
      
      def process_ansi(str)
        str.gsub(/\e\[32m/,      '<span class="ansi-green">').
            gsub(/\e\[90m/,      '<span class="ansi-gray">').
            gsub(/\e\[(0;){0,1}31m/, '<span class="ansi-red">').
            gsub(/\e\[1m/,       '<span class="ansi-bold">').
            gsub(/\e\[0m/,       '</span>')
      end
    end
  end
end
