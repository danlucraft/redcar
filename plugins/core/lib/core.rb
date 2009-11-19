
require "core/logger"
require "core/controller"
require "core/gui"
require "core/model"
require "core/observable"
require "core/plugin"

module Redcar
  class Core
    include HasLogger
    
    def self.load
      Core::Logger.init
    end
    
    def self.platform
      case Config::CONFIG["target_os"]
      when /darwin/
        :osx
      when /mswin/
        :windows
      when /linux/
        :linux
      end
    end
  end
end

