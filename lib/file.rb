
module Redcar
  class RedcarFile
    class << self
      def load(filename)
        IO.readlines(filename).join
      end
      
      def save(filename, contents)
        File.open(filename, "w") do |f|
          f.puts contents
        end
      end
    end
  end
end
