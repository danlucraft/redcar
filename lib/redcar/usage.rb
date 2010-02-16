
module Redcar
  
  class Usage
    def version_string
      str = "Redcar #{Redcar::VERSION} ( #{RUBY_PLATFORM} )"
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
        puts "        --font=FONT  Choose font"
        puts "   --font-size=SIZE  Choose font point size"
        puts "      --theme=THEME  Choose Textmate theme"
        puts "--multiple-instance  Don't attempt to run from an existing instance"
        puts "          --verbose  Set $VERBOSE to true"
        puts "        filename1, filename2, dirname1, dirname2 ..."
        puts
        puts
        puts "To download jars:"
        puts
        puts "   $ [sudo] redcar install"
        puts
        puts "To associate with right click in windows explorer:"
        puts
        puts "  C:> redcar --associate_with_any_right_click"
        puts
        exit
      end
    end
  end
end
