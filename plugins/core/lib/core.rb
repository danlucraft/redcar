
require "core/controller"
require "core/gui"
require "core/model"
require "core/observable"
require "core/plugin"

module Redcar
  class Core
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

