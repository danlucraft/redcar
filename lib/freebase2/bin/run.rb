$FREEBASE_APPLICATION = "freebase"

$:.unshift "../lib"

require 'rbconfig'

module FreeBASE
  module Example
    class Bootstrap
      #version information
      VERSION_MAJOR = 1
      VERSION_MINOR = 2
      VERSION_RELEASE = 0
      
      ##
      # Start up the FreeBASE and block until shut down event is received
      #
      # dir:: [String] The directory which holds the properties.yaml and/or default.yaml
      #
      def self.startup(dir)
      
        require 'freebase/freebase'
        
        #verify the existence of the supplied directory
        begin
          files = Dir.entries(".")
        rescue
          raise "Could not locate directory '.'"
        end
        
        #make sure that either freebase.yaml exists or default.yaml
        unless files.include?("freebase.yaml")
          raise "Could not locate default.yaml in #{dir}" unless files.include?("default.yaml")
        end
        
        #This method will not return until FreeBASE is closed (shut down)
        FreeBASE::Core.startup("freebase.yaml", "default.yaml")
      end
    end
  end
end

if $0==__FILE__
  baseDir = '.'
  baseDir = ARGV[0] if ARGV.size > 0
  FreeBASE::Example::Bootstrap.startup(baseDir)
end

