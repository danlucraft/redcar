
puts "loading redcar for cucumber"

Thread.new do
  module Redcar
    module App
      class << self
        attr_accessor :ARGV
      end
      self.ARGV = []
    end
    
    module Testing
      class InternalCucumberRunner
        class << self
          attr_accessor :in_cucumber_process
          attr_accessor :ready_for_cucumber
        end
        self.in_cucumber_process = true
      end
    end
  end
  
  load File.dirname(__FILE__) + "/../../../bin/redcar"
end

loop do
  sleep 0.1
  break if Redcar::Testing::InternalCucumberRunner.ready_for_cucumber
end

