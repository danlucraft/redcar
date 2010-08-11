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
      
      def initialize
        @ansi_stack = []
        @ansi_colors = %w(black red green yellow blue purple cyan gray) 
      end
      
      def process_ansi(str)
        str.gsub(/\e\[(([0,1]);?)?((\d)(\d))?m/) do |m|
          match = $~
          if match[2] == "0"
            "</span>"
          else
            style = ""          
            style += "ansi-bold "       if match[2] == "1"
            style += "ansi-light "      if match[4] == "9"
            style += "ansi-#{@ansi_colors[match[5].to_i]}" if match[4] == "3"
            %Q|<span class="#{style}">|
          end
        end
      end
    end
  end
end
