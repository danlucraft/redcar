
require 'java'
require 'fileutils'

require "core/logger"
require "core/controller"
require "core/gui"
require "core/interface"
require "core/model"
require "core/observable"
require "core/observable_struct"
require "core/plugin"
require "core/plugin/storage"

module Redcar
  class Core
    include HasLogger
    
    def self.loaded
      Core::Logger.init
      unless File.exist?(Redcar.user_dir)
        FileUtils.mkdir(Redcar.user_dir)
      end
    end
  end
end
