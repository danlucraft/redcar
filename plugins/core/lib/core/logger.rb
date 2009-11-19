module Redcar
  def self.logger
    Core::Logger.root_logger
  end
  
  class Core
    module HasLogger
      def logger
        Logging::Logger[self.class.name]
      end
    end
    
    module Logger
      def self.init
        if level = ENV["REDCAR_LOG"]
          appender = Logging::Appenders.stdout(:level => level)
          root_logger.add_appenders(appender)
        end
      end
      
      def self.root_logger
        Logging::Logger[:root]
      end
    end
  end
end