
require 'fileutils'

require "core/reentry_helpers"
require "core/controller"
require "core/gui"
require "core/has_spi"
require "core/interface"
require "core/model"
require "core/observable"
require "core/observable_struct"
require "core/persistent_cache"
require "core/plugin"
require "core/plugin/storage"

begin
  require 'java'
  require "core/task"
  require "core/task_queue"
  require "core/resource"
rescue LoadError => e
end

module Redcar
  def self.tmp_dir
    path = File.join(Redcar.user_dir, "tmp")
    unless File.exists?(path)
      FileUtils.mkdir(path)
    end
    path
  end
    
  class Core
    def self.loaded
      unless File.exist?(Redcar.user_dir)
        FileUtils.mkdir(Redcar.user_dir)
      end
      PersistentCache.storage_dir = File.join(Redcar.user_dir, "cache")
    end
  end
end
