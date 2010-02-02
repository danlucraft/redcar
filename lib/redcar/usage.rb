
module Redcar
  
  class Usage
    def version_string
      str = "Redcar #{Redcar::VERSION} (jruby )"
      puts str
    end
    
    def version_requested
      if ARGV.include?("-v")
        puts "Redcar #{Redcar::VERSION}"
        exit
      end
    end

    def help_requested
      if ARGV.include?("-h") or ARGV.include?("--help")
        puts
        puts "       --font=FONT  Choose font"
        puts "  --font-size=SIZE  Choose font point size"
        puts "     --theme=THEME  Choose Textmate theme"
        puts
        puts "To download jars:"
        puts
        puts "   $ [sudo] redcar install"
        puts
        exit
      end
    end
  end
end
