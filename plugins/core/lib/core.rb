
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
  
  class TimeoutError < StandardError; end

  def self.timeout(limit)
    x = Thread.current
    result = nil
    y = Thread.new do
      begin
        result = yield
      rescue Object => e
        x.raise e
      end
    end
    s = Time.now
    loop do
      if not y.alive?
        break
      elsif Time.now - s > limit
        y.kill
        raise Redcar::TimeoutError, "timed out after #{Time.now - s}s"
        break
      end
      sleep 0.1
    end
    result
  end
end
