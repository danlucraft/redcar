
require "core/logger"
require "core/controller"
require "core/gui"
require "core/model"
require "core/observable"
require "core/plugin"
require "core/plugin/storage"

module Redcar
  class Core
    include HasLogger
    
    def self.loaded
      Core::Logger.init
    end
    
    # Platform symbol
    #
    # @return [:osx/:windows/:linux]
    def self.platform
      case Config::CONFIG["target_os"]
      when /darwin/
        :osx
      when /mswin|mingw/
        :windows
      when /linux/
        :linux
      end
    end
    
    # Platform specific ~/.redcar
    #
    # @return [String] expanded path
    def self.user_dir
      if platform == :windows
        if ENV['USERPROFILE'].nil?
          userdir = "C:/My Documents/.redcar/"
        else
          userdir = File.join(ENV['USERPROFILE'], ".redcar")
        end
      else
        userdir = File.join(ENV['HOME'], ".redcar") unless ENV['HOME'].nil?
      end
      File.expand_path(userdir)
    end

  end
end

