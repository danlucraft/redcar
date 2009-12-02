
module Redcar
  
  class Usage
    def version_requested
      if ARGV.include?("-v")
        puts "Redcar #{Redcar::VERSION}"
        exit
      end
    end

    def help_requested
      if ARGV.include?("-h")
        puts "Redcar #{Redcar::VERSION}"
        puts
        puts "       --font=FONT  Choose font"
        puts "  --font-size=SIZE  Choose font point size"
        puts
        exit
      end
    end
  end
end
