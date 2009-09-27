
module Redcar
  # A simple DBus listener thread that watches for method calls across DBus.
  class DBus
    def self.start_listener
      Thread.new do
        begin
          main = ::DBus::Main.new  
          main << @bus
          main.run  
        rescue Object => e
          puts e.message
          puts e.backtrace
        end
      end
    end
  end
end
