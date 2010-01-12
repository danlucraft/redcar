require 'logger'

module Redcar
  def self.logger
    Core::Logger.root_logger
  end
  
  class Core
    module HasLogger
      def logger
        Core::Logger.root_logger
      end
    end
    
    module Logger
      def self.init
        level = ENV["REDCAR_LOG"] || "error"
        root_logger.level = ::Logger::ERROR
#        appender = Logging::Appenders.stdout(:level => level)
#        root_logger.add_appenders(appender)
      end
      
      def self.root_logger
        @logger ||= ::Logger.new(STDOUT)
      end
    end
  end
end