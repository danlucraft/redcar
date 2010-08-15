
module Redcar
  module Scm
    module Git
      class ConfigFile
        
        def self.parse(path)
          f = File.open(path)
          config = {}
          current = ""
          
          f.each_line do |line|
            line = line.rstrip
            if line[0, 1] == "[" and line[line.length - 1, 1] == "]"
              current = line[1, line.length - 2]
              config[current] ||= {}
            elsif line[0, 1] == "\t"
              line = line[1, line.length - 1]
              
              values = line.split(' = ', 2)
              config[current][values[0]] = values[1]
            end
          end
          f.close
          config
        end
        
      end
    end
  end
end
